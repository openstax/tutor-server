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

  def initialize(task_plan:, individualized_tasking_plans:)
    super

    @exercise_ids = task_plan.settings['exercise_ids']
    raise "No exercises selected" if @exercise_ids.blank?

    @exercises = ecosystem.exercises_by_ids(@exercise_ids)

    @core_page_ids = @exercises.map{ |ex| ex.page.id }.uniq
  end

  def build_tasks
    roles = individualized_tasking_plans.map(&:target)
    histories = GetHistory[roles: roles, type: :homework]

    individualized_tasking_plans.map do |tasking_plan|
      build_homework_task(exercises: @exercises, history: histories[tasking_plan.target],
                          individualized_tasking_plan: tasking_plan)
    end
  end

  protected

  def k_ago_map(num_spaced_practice_exercises)
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
      raise "could not determine k-ago map for num_spaced_practice_exercises=#{
              num_spaced_practice_exercises
            }"
    end
  end

  def num_personalized_exercises
    1
  end

  def build_homework_task(exercises:, history:, individualized_tasking_plan:)
    task = build_task(type: :homework, default_title: 'Homework',
                      individualized_tasking_plan: individualized_tasking_plan)

    reset_used_exercises

    add_core_steps!(task: task, exercises: exercises)

    add_spaced_practice_exercise_steps!(
      task: task, core_page_ids: @core_page_ids, history: history,
      k_ago_map: k_ago_map(num_spaced_practice_exercises), pool_type: :homework_dynamic
    )

    add_personalized_exercise_steps!(
      task: task, count: num_personalized_exercises,
      personalized_placeholder_strategy_class: Tasks::PlaceholderStrategies::HomeworkPersonalized
    )
  end

  def add_core_steps!(task:, exercises:)
    exercises.each do |exercise|
      add_exercise_step!(task: task, exercise: exercise, group_type: :core_group)
    end

    task
  end

  def num_spaced_practice_exercises
    exercises_count_dynamic = task_plan[:settings]['exercises_count_dynamic']
    num_spaced_practice_exercises = [0, exercises_count_dynamic-1].max
    num_spaced_practice_exercises
  end

end
