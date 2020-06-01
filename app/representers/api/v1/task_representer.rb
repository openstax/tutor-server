module Api::V1
  class TaskRepresenter < Roar::Decorator
    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true

    property :title,
             type: String,
             writeable: false,
             readable: true

    property :description,
             type: String,
             writeable: false,
             readable: true

    property :task_type,
             as: :type,
             type: String,
             writeable: false,
             readable: true

    property :due_at_without_extension,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at_without_extension) },
             schema_info: {
               description: 'When the task was due before any extensions (nil means never due)'
             }

    property :due_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             schema_info: { description: 'When the task is due (nil means never due)' }

    property :closes_at_without_extension,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(closes_at_without_extension) },
             schema_info: {
               description: 'When the task closed before any extensions (nil means never due)'
             }

    property :closes_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(closes_at) },
             schema_info: { description: 'When the task closes (nil means never closes)' }

    property :auto_grading_feedback_on,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               type: 'enum',
               description: <<~DESCRIPTION
                 When feedback should be shown to students for automatically graded questions.
                 One of either "answer", "due" or "publish"
               DESCRIPTION
             }

    property :manual_grading_feedback_on,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               type: 'enum',
               description: <<~DESCRIPTION
                 When feedback should be shown to students for manually graded questions.
                 One of either "grade" or "publish"
               DESCRIPTION
             }

    property :completion_weight,
             type: Float,
             readable: true,
             writeable: false

    property :correctness_weight,
             type: Float,
             readable: true,
             writeable: false

    property :late_work_penalty_applied,
             type: String,
             readable: true,
             writeable: false

    property :late_work_penalty_per_period,
             type: Float,
             readable: true,
             writeable: false

    property :withdrawn?,
             as: :is_deleted,
             readable: true,
             writeable: false,
             schema_info: {
               type: 'boolean',
               description: "Whether or not this task has been withdrawn by the teacher"
             }

    property :students,
             type: Array,
             writeable: false,
             readable: true,
             getter: ->(*) do
               roles.map { |role| { role_id: role.id, name: role.course_member.name } }
             end,
             schema_info: {
               required: true,
               description: "The students who were assigned this task"
             }

    property :spy,
             type: Object,
             readable: true,
             writeable: false

    collection :task_steps,
               as: :steps,
               writeable: false,
               readable: true,
               extend: TaskStepRepresenter,
               schema_info: {
                 required: true,
                 description: "The steps which this task is composed of"
               }

    # Make sure we always preload the all task steps' content and assign available_points
    # before representing the task
    def initialize(task)
      # Preload all taskeds and exercise content
      task.preload_content

      # Preload all available points
      task.exercise_and_placeholder_steps.each_with_index do |task_step, idx|
        task_step.tasked.available_points = task.available_points_per_question_index[idx]
      end

      super task
    end
  end
end
