module Api::V1
  class TaskRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :task_type,
             as: :type,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true, description: "The type of this Task" }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :description,
             type: String,
             writeable: false,
             readable: true

    property :opens_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(opens_at) },
             schema_info: {
               description: "When the task is available to be worked (nil means available immediately)"
             }

    property :due_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             schema_info: { description: "When the task is due (nil means never due)" }

    property :last_worked_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_worked_at) },
             schema_info: {
               description: "When the task was last worked (nil means not yet worked)"
             }

    property :is_shared?,
             as: :is_shared,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "Whether or not the task is shared ('turn in one assignment')"
             }

    collection :task_steps,
               as: :steps,
               writeable: false,
               readable: true,
               extend: TaskStepRepresenter,
               getter: ->(*) do
                 task_steps.tap do |task_steps|
                   ActiveRecord::Associations::Preloader.new.preload(
                     task_steps, [:tasked, page: :chapter]
                   )
                 end
               end,
               schema_info: {
                 required: true,
                 description: "The steps which this Task is composed of"
               }

    property :feedback_available?,
             as: :is_feedback_available,
             writeable: false,
             readable: true,
             schema_info: { type: 'boolean',
                            description: "If the feedback should be shown for the task" }

    property :withdrawn?,
             as: :is_deleted,
             readable: true,
             writeable: false,
             schema_info: {
               type: 'boolean',
               description: "Whether or not this task has been withdrawn by the teacher"
             }

    property :spy,
             type: Object,
             readable: true,
             writeable: false

  end
end
