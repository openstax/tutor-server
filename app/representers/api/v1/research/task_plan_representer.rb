class Api::V1::Research::TaskPlanRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :uuid,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :content_ecosystem_id,
           as: :ecosystem_id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :type,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :title,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :description,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :is_feedback_immediate,
           readable: true,
           writeable: false,
           if: ->(*) { type == 'homework' },
           schema_info: { required: true, type: 'boolean' }

  property :is_draft,
           readable: true,
           writeable: false,
           getter: ->(*) { is_draft? },
           schema_info: { required: true, type: 'boolean' }

  property :is_preview,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :is_publishing,
           readable: true,
           writeable: false,
           getter: ->(*) { is_publishing? },
           schema_info: { required: true, type: 'boolean' }

  property :is_published,
           readable: true,
           writeable: false,
           getter: ->(*) { is_published? },
           schema_info: { required: true, type: 'boolean' }

  property :first_published_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(first_published_at) },
           schema_info: { required: true }

  property :last_published_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(last_published_at) },
           schema_info: { required: true }

  property :settings,
           type: Object,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :cloned_from_id,
           type: String,
           readable: true,
           writeable: false

  collection :tasking_plans,
             extend: Api::V1::Research::TaskingPlanRepresenter,
             readable: true,
             writeable: false,
             schema_info: { required: true }
end
