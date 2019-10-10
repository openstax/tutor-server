class Api::V1::Research::TaskingPlanRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :target_id,
           type: String,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :target_type,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { target_type.demodulize.downcase },
           schema_info: { required: true }

  property :opens_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(opens_at) },
           schema_info: { required: true }

  property :due_at,
           type: String,
           readable: true,
           writeable: false,
           getter: ->(*) { DateTimeUtilities.to_api_s(due_at) },
           schema_info: { required: true }
end
