module Api::V1
  class MetataskRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :due_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
             schema_info: { description: "When the metatask is due (nil means never due)" }

    property :last_worked_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_worked_at) },
             schema_info: {
               description: "When the metatask was last worked (nil means not yet worked)"
             }

    collection :metatask_steps,
               as: :metatask_steps,
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

    property :feedback_available?,
             as: :is_feedback_available,
             writeable: false,
             readable: true,
             schema_info: { type: 'boolean',
                            description: "If the feedback should be shown for the task" }
  end
end
