class Api::V1::BookTocRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::BookPartTocRepresenter
end