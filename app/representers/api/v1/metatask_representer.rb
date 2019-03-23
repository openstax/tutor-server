module Api::V1
  class MetataskRepresenter < Roar::Decorator

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
             schema_info: { description: "When the metatask is due (nil means never due)" }

    property :feedback_at,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(feedback_at) },
             schema_info: {
               type: 'date',
               description: "Feedback should be shown for the task after this time"
             }

    collection :steps,
               writeable: false,
               readable: true,
               extend: MetataskStepRepresenter,
               getter: ->(*) do
                 task_steps.tap do |task_steps|
                   ActiveRecord::Associations::Preloader.new.preload(
                     task_steps, [:tasked, page: :chapter]
                   )
                 end
               end,
               schema_info: {
                 required: true,
                 description: "The steps which this Metatask is composed of"
               }

  end
end
