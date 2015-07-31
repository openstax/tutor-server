class Api::V1::JobsRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::JobRepresenter
end
