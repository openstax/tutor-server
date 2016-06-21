class Tasks::Assistants::HomeworkAssistant < Tasks::Assistants::GenericAssistant

  def self.schema
    '{
      "type": "object",
      "required": [
        "exercise_ids",
        "exercises_count_dynamic"
      ],
      "properties": {
        "exercise_ids": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "minItems": 1,
          "uniqueItems": true
        },
        "exercises_count_dynamic": {
          "type": "integer",
          "minimum": 2,
          "maximum": 4
        },
        "page_ids": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      },
      "additionalProperties": false
    }'
  end

  def initialize(task_plan:, taskees:)
    super

    collect_exercises

    @core_page_ids = @exercises.map{ |ex| ex.page.id }.uniq

    @tag_exercise = {}
    @exercise_pages = {}
    @page_pools = {}
    @pool_exercises = {}
    @ecosystems_map = {}
  end

  def build_tasks
    # Don't load too many histories at once so we don't risk running out of memory
    taskees.each_slice(5).flat_map do |taskee_slice|
      histories = GetHistory[roles: taskee_slice, type: :homework]

      taskee_slice.map do |taskee|
        build_homework_task(taskee: taskee, exercises: @exercises, history: histories[taskee])
      end
    end
  end

  protected

  def self.k_ago_map(num_spaced_practice_exercises)
    ## Entries in the list have the form:
    ##   [from-this-many-events-ago, choose-this-many-exercises]
    case num_spaced_practice_exercises
    when 0
      []
    when 1
      [ [2,1] ]
    when 2
      [ [2,1], [4,1] ]
    when 3
      [ [2,2], [4,1] ]
    when 4
      [ [2,2], [4,2] ]
    else
      raise "could not determine k-ago map for num_spaced_practice_exercises=#{num_spaced_practice_exercises}"
    end
  end

  def self.num_personalized_exercises
    1
  end

  def collect_exercises
    @exercise_ids = task_plan.settings['exercise_ids']
    raise "No exercises selected" if @exercise_ids.blank?

    @exercises = ecosystem.exercises_by_ids(@exercise_ids)
  end

  def build_homework_task(taskee:, exercises:, history:)
    task = build_task

    add_core_steps!(task: task, exercises: exercises)
    add_spaced_practice_exercise_steps!(task: task, taskee: taskee, history: history)
    add_personalized_exercise_steps!(task: task, taskee: taskee)
  end

  def build_task
    title    = task_plan.title || 'Homework'
    description = task_plan.description

    Tasks::BuildTask[
      task_plan:   task_plan,
      task_type:   :homework,
      title:       title,
      description: description
    ].tap{ |task| AddSpyInfo[to: task, from: ecosystem] }
  end

  def add_core_steps!(task:, exercises:)
    exercises.each do |exercise|
      TaskExercise.call(task: task, exercise: exercise) do |step|
        step.group_type = :core_group
        step.add_related_content(exercise.page.related_content)
      end
    end
  end

  def assign_spaced_practice_exercise(task:, exercise:)
    TaskExercise.call(task: task, exercise: exercise) do |step|
      step.group_type = :spaced_practice_group
      step.add_related_content(exercise.page.related_content)
    end
  end

  def add_spaced_practice_exercise_steps!(task:, taskee:, history:)
    history = add_current_task_to_individual_history(
      task: task, core_page_ids: @core_page_ids, history: history
    )

    core_exercise_numbers = history.exercise_numbers.first

    course = task_plan.owner

    spaced_practice_status = []

    num_spaced_practice_exercises = get_num_spaced_practice_exercises
    self.class.k_ago_map(num_spaced_practice_exercises).each do |k_ago, num_requested|
      # Not enough history
      if k_ago >= history.total_count
        spaced_practice_status << "Not enough tasks in history to fill the #{k_ago}-ago slot"
        next
      end

      spaced_ecosystem_id = history.ecosystem_ids[k_ago]

      # Get core pages from the history
      spaced_page_ids = history.core_page_ids[k_ago]
      spaced_pages = get_pages(spaced_page_ids)

      ecosystems_map = map_spaced_ecosystem_id_to_ecosystem(spaced_ecosystem_id)

      # Map the core pages to exercises in the new ecosystem
      spaced_exercises = ecosystems_map.map_pages_to_exercises(
        pages: spaced_pages, pool_type: :homework_dynamic
      ).values.flatten.uniq

      filtered_exercises = FilterExcludedExercises[
        exercises: spaced_exercises, course: course,
        additional_excluded_numbers: core_exercise_numbers
      ]

      chosen_exercises = ChooseExercises[
        exercises: filtered_exercises, count: num_requested, history: history
      ]

      # Set related_content and add the exercises to the task
      chosen_exercises.each do |chosen_exercise|
        assign_spaced_practice_exercise(task: task, exercise: chosen_exercise)
      end

      spaced_practice_status << "Could not completely fill the #{k_ago}-ago slot" \
        if chosen_exercises.size < num_requested
    end

    spaced_practice_status << 'Completely filled' if spaced_practice_status.empty?

    AddSpyInfo[to: task, from: { spaced_practice: spaced_practice_status }]

    task
  end

  def get_num_spaced_practice_exercises
    exercises_count_dynamic = task_plan[:settings]['exercises_count_dynamic']
    num_spaced_practice_exercises = [0, exercises_count_dynamic-1].max
    num_spaced_practice_exercises
  end

  def add_personalized_exercise_steps!(task:, taskee:)
    task.personalized_placeholder_strategy = \
      Tasks::PlaceholderStrategies::HomeworkPersonalized.new \
      if self.class.num_personalized_exercises > 0

    self.class.num_personalized_exercises.times do
      task_step = Tasks::Models::TaskStep.new(task: task)
      tasked_placeholder = Tasks::Models::TaskedPlaceholder.new(task_step: task_step)
      tasked_placeholder.placeholder_type = :exercise_type
      task_step.tasked = tasked_placeholder
      task_step.group_type = :personalized_group
      task.add_step(task_step)
    end

    task
  end

end
