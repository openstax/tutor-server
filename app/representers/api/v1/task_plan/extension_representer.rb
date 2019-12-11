class Api::V1::TaskPlan::ExtensionRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :entity_role_id,
           as: :role_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           readable: true,
           writeable: true,
           getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
           schema_info: { required: true }

  property :closes_at,
           type: String,
           readable: true,
           writeable: true,
           getter: ->(*) { DateTimeUtilities.to_api_s(closes_at) },
           schema_info: { required: true }
end
