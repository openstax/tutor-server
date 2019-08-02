class Api::V1::Demo::BaseRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion
end
