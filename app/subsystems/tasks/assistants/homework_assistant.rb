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

  def build_tasks
    collect_exercises

    @tag_exercise = {}
    @exercise_pages = {}
    @page_pools = {}
    @pool_exercises = {}
    @ecosystems_map = {}
    @taskees.collect do |taskee|
      build_homework_task(
        taskee:       taskee,
        exercises:    @exercises
      ).entity_task
    end
  end

  def updated_attributes_for(tasking_plan:)
    attributes = super
    attributes.merge({feedback_at: tasking_plan.task_plan.is_feedback_immediate? ? tasking_plan.opens_at : tasking_plan.due_at})
  end

  protected

  def collect_exercises
    @exercise_ids = @task_plan.settings['exercise_ids']
    raise "No exercises selected" if @exercise_ids.blank?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(@task_plan.ecosystem)
    @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)

    @exercises = @ecosystem.exercises_by_ids(@exercise_ids)
  end

  def build_homework_task(taskee:, exercises:)
    task = build_task

    add_core_steps!(task: task, exercises: exercises)
    add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
    add_personalized_exercise_steps!(task: task, taskee: taskee)
  end

  def build_task
    title    = @task_plan.title || 'Homework'
    description = @task_plan.description

    task = Tasks::BuildTask[
      task_plan:   @task_plan,
      task_type:   :homework,
      title:       title,
      description: description
    ]
    AddSpyInfo[to: task, from: @ecosystem]
    return task
  end

  def add_core_steps!(task:, exercises:)
    exercises.each do |exercise|
      step = add_exercise_step(task: task, exercise: exercise)
      step.group_type = :core_group
      step.add_related_content(exercise.page.related_content)
    end

    task
  end

  def add_exercise_step(task:, exercise:)
    step = Tasks::Models::TaskStep.new(task: task)
    TaskExercise[task_step: step, exercise: exercise]
    task.task_steps << step
    step
  end

  def assign_spaced_practice_exercise(task:, exercise:)
    related_content = exercise.page.related_content

    step = add_exercise_step(task: task, exercise: exercise)
    step.group_type = :spaced_practice_group

    step.add_related_content(related_content)
  end

  def add_spaced_practice_exercise_steps!(task:, taskee:)
    # Get taskee's reading history
    history = GetHistory.call(role: taskee, type: :homework, current_task: task).outputs

    core_exercise_numbers = history.exercises.first.map(&:number)

    course = @task_plan.owner

    spaced_practice_status = []

    num_spaced_practice_exercises = get_num_spaced_practice_exercises
    self.class.k_ago_map(num_spaced_practice_exercises).each do |k_ago, num_requested|
      # Not enough history
      if k_ago >= history.tasks.size
        spaced_practice_status << "Not enough tasks in history to fill the #{k_ago}-ago slot"
        next
      end

      spaced_ecosystem = history.ecosystems[k_ago]

      # Get pages from the exercise steps selected by the teacher in the spaced assignment
      spaced_tasked_exercises = history.tasked_exercises[k_ago]
      spaced_core_tasked_exercises = spaced_tasked_exercises.select do |tasked_exercise|
        tasked_exercise.task_step.core_group?
      end
      spaced_core_pages = spaced_core_tasked_exercises.collect do |tasked_exercise|
        model = tasked_exercise.exercise.page
        Content::Page.new(strategy: model.wrap)
      end.uniq

      # Reuse Ecosystems map when possible
      @ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find(
        from_ecosystems: [spaced_ecosystem, @ecosystem].uniq, to_ecosystem: @ecosystem
      )

      # Map the core pages to exercises in the new ecosystem
      spaced_exercises = @ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_core_pages, pool_type: :homework_dynamic
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
    exercises_count_dynamic = @task_plan[:settings]['exercises_count_dynamic']
    num_spaced_practice_exercises = [0, exercises_count_dynamic-1].max
    num_spaced_practice_exercises
  end

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

  def add_personalized_exercise_steps!(task:, taskee:)
    task.personalized_placeholder_strategy = Tasks::PlaceholderStrategies::HomeworkPersonalized.new \
      if self.class.num_personalized_exercises > 0

    self.class.num_personalized_exercises.times do
      task_step = Tasks::Models::TaskStep.new(task: task)
      tasked_placeholder = Tasks::Models::TaskedPlaceholder.new(task_step: task_step)
      tasked_placeholder.placeholder_type = :exercise_type
      task_step.tasked = tasked_placeholder
      task_step.group_type = :personalized_group
      task.task_steps << task_step
    end

    task
  end

  def self.num_personalized_exercises
    1
  end

end
