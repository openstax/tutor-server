class Api::V1::Demo::CourseRepresenter < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  # One of either id or name is required
  property :id,
           type: String,
           readable: true,
           writeable: true

  property :name,
           type: String,
           readable: true,
           writeable: true
end
