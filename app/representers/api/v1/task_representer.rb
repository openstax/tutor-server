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
             type: DateTime,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(opens_at) },
             schema_info: {
               description: "When the task is available to be worked (nil means available immediately)"
             }

    property :due_at,
             type: DateTime,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             schema_info: { description: "When the task is due (nil means never due)" }

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
               decorator: TaskStepRepresenter,
               schema_info: {
                 required: true,
                 description: "The steps which this Task is composed of"
               }

  end
end
