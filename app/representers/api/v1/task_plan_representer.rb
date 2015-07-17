module Api::V1
  class TaskPlanRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :type,
             type: String,
             readable: true,
             writeable: true

    property :title,
             type: String,
             readable: true,
             writeable: true

    property :description,
             type: String,
             readable: true,
             writeable: true

    property :is_publish_requested,
             readable: true,
             writeable: true,
             getter: ->(*) { is_publish_requested? },
             schema_info: { type: 'boolean' }


    property :publish_last_requested_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(publish_last_requested_at) }

    property :publish_job_uuid,
             type: String,
             readable: true,
             writeable: false

    property :publish_job_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { "/api/jobs/#{publish_job_uuid}" },
             if: ->(*) { !publish_job_uuid.nil? }

    property :published_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(published_at) }

    property :settings,
             type: Object,
             readable: true,
             writeable: true

    collection :tasking_plans,
               class: ::Tasks::Models::TaskingPlan,
               decorator: TaskingPlanRepresenter,
               readable: true,
               writeable: true

  end
end
