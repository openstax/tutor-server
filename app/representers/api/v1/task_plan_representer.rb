module Api::V1
  class TaskPlanRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :is_trouble,
             readable: true,
             writeable: false,
             schema_info: { type: 'boolean' },
             if: ->(*) { respond_to? :is_trouble }

    property :content_ecosystem_id,
             as: :ecosystem_id,
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
             readable: false,
             writeable: true,
             schema_info: { type: 'boolean' }

    property :is_feedback_immediate,
             readable: true,
             writeable: true,
             if: ->(*) { type == 'homework' },
             schema_info: { type: 'boolean' }

    property :is_draft,
             readable: true,
             writeable: false,
             getter: ->(*) { is_draft? },
             schema_info: { type: 'boolean' }

    property :is_publishing,
             readable: true,
             writeable: false,
             getter: ->(*) { is_publishing? },
             schema_info: { type: 'boolean' }

    property :is_published,
             readable: true,
             writeable: false,
             getter: ->(*) { is_published? },
             schema_info: { type: 'boolean' }

    property :publish_last_requested_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(publish_last_requested_at) }

    property :publish_job,
             extend: JobRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) { Jobba.find(publish_job_uuid) },
             if: ->(*) { !publish_job_uuid.blank? }

    property :publish_job_url,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { "/api/jobs/#{publish_job_uuid}" },
             if: ->(*) { !publish_job_uuid.blank? }

    property :first_published_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(first_published_at) }

    property :last_published_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_published_at) }

    property :settings,
             type: Object,
             readable: true,
             writeable: true

    property :cloned_from_id,
             type: String,
             readable: true,
             writeable: true

    collection :tasking_plans,
               instance: ->(*) { ::Tasks::Models::TaskingPlan.new(time_zone: owner.time_zone) },
               extend: TaskingPlanRepresenter,
               setter: RailsCollectionSetter,
               readable: true,
               writeable: true

  end
end
