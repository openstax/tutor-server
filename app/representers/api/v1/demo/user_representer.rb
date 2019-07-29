class Api::V1::Demo::UserRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :username,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :full_name,
           type: String,
           readable: true,
           writeable: true

  property :first_name,
           type: String,
           readable: true,
           writeable: true

  property :last_name,
           type: String,
           readable: true,
           writeable: true
end
