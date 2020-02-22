class Tasks::Assistants::HomeworkAssistant < Tasks::Assistants::GenericAssistant
  def self.schema
    '{
      "type": "object",
      "properties": {
        "exercises": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "id": {
                "type": "string"
              },
              "points": {
                "type": "array",
                "items": {
                  "type": "integer"
                },
                "minItems": 1
              }
            },
            "required": [
              "id",
              "points"
            ],
            "additionalProperties": false
          },
          "minItems": 1,
          "uniqueItems": true
        },
        "exercises_count_dynamic": {
          "type": "integer",
          "minimum": 0,
          "maximum": 4
        },
        "page_ids": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      },
      "required": [
        "exercises",
        "exercises_count_dynamic"
      ],
      "additionalProperties": false
    }'
  end

  def initialize(task_plan:, individualized_tasking_plans:)
    super

    @exercise_hashes = task_plan.settings['exercises']
    raise "No exercises selected" if @exercise_hashes.blank?

    @exercises = ecosystem.exercises_by_ids(@exercise_hashes.map { |ex| ex['id'] })

    @core_page_ids = @exercises.map { |ex| ex.page.id }.uniq
  end

  def build_tasks
    roles = individualized_tasking_plans.map(&:target)

    individualized_tasking_plans.map do |tasking_plan|
      build_homework_task(exercises: @exercises, individualized_tasking_plan: tasking_plan)
    end
  end

  protected

  def num_spaced_practice_exercises
    exercises_count_dynamic = task_plan[:settings]['exercises_count_dynamic'].to_i
    num_spaced_practice_exercises = [0, exercises_count_dynamic].max
    num_spaced_practice_exercises
  end

  def build_homework_task(exercises:, individualized_tasking_plan:)
    task = build_task(type: :homework, default_title: 'Homework',
                      individualized_tasking_plan: individualized_tasking_plan)

    reset_used_exercises

    add_core_steps!(task: task, exercises: exercises)

    add_placeholder_steps! task: task,
                           group_type: :spaced_practice_group,
                           is_core: false,
                           count: num_spaced_practice_exercises,
                           labels: [ 'review' ]
  end

  def add_core_steps!(task:, exercises:)
    exercises.each do |exercise|
      add_exercise_step!(task: task, exercise: exercise, group_type: :fixed_group, is_core: true)
    end

    task
  end
end
