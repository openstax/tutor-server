class Api::V1::Demo::Course::Period::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :name,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :enrollment_code,
           type: String,
           readable: true,
           writeable: true

  collection :students,
             extend: Api::V1::Demo::UserRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
