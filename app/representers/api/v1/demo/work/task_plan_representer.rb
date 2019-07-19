class Api::V1::Demo::Work::TaskPlanRepresenter < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  # One of either id or title is required
  property :id,
           type: String,
           readable: true,
           writeable: true

  property :title,
           type: String,
           readable: true,
           writeable: true

  collection :tasks,
             extend: Api::V1::Demo::Work::TaskRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
