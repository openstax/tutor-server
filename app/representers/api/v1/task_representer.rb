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

    property :due_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             schema_info: { description: "When the task is due (nil means never due)" }

    property :feedback_at,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(feedback_at) },
             schema_info: {
               type: 'date',
               description: "Feedback should be shown for the task after this time"
             }

    collection :task_steps,
               as: :steps,
               writeable: false,
               readable: true,
               extend: TaskStepRepresenter,
               schema_info: {
                 required: true,
                 description: "The steps which this task is composed of"
               }

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
