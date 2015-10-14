class Tasks::Assistants::HomeworkAssistant

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
          }
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
    @task_plan = task_plan
    @taskees = taskees

    collect_exercises

    @tag_exercise = {}
    @exercise_pages = {}
    @page_pools = {}
    @pool_exercises = {}
    @ecosystems_map = {}
  end

  def build_tasks
    @taskees.collect do |taskee|
      build_homework_task(
        taskee:       taskee,
        exercises:    @exercises
      ).entity_task
    end
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

  def add_spaced_practice_exercise_steps!(task:, taskee:)
    # Get taskee's reading history
    history = GetHistory.call(role: taskee, type: :homework, current_task: task).outputs

    all_worked_exercise_numbers = history.exercises.flatten.collect{ |ex| ex.number }

    num_spaced_practice_exercises = get_num_spaced_practice_exercises
    self.class.k_ago_map(num_spaced_practice_exercises).each do |k_ago, number|
      # Not enough history
      break if k_ago >= history.tasks.size

      spaced_ecosystem = history.ecosystems[k_ago]

      # Get pages from the exercise steps
      spaced_pages = history.exercises[k_ago].collect(&:page).uniq

      # Reuse Ecosystems map when possible
      @ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find(
        from_ecosystems: [spaced_ecosystem, @ecosystem].uniq, to_ecosystem: @ecosystem
      )

      # Map the page to exercises in the new ecosystem
      spaced_exercises = @ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_pages, pool_type: :homework_dynamic
      )

      # Exclude exercises already worked (by number)
      candidate_exercises = spaced_exercises.values.flatten.uniq.reject do |ex|
        all_worked_exercise_numbers.include?(ex.number)
      end

      # Not enough exercises
      break if candidate_exercises.size < number

      # Randomize and grab the required number of exercises
      chosen_exercises = candidate_exercises.shuffle.first(number)

      # Set related_content and add the exercise to the task
      chosen_exercises.each do |chosen_exercise|
        related_content = chosen_exercise.page.related_content

        step = add_exercise_step(task: task, exercise: chosen_exercise)
        step.group_type = :spaced_practice_group

        step.add_related_content(related_content)
      end
    end

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
