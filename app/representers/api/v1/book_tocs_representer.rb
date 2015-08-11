class Api::V1::BookTocsRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::BookTocRepresenter
end
