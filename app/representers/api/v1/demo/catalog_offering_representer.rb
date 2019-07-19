class Api::V1::Demo::CatalogOfferingRepresenter < Roar::Decorator
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
end
