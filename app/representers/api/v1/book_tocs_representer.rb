# If you modify this representer, you must run `Content::Models::Ecosystem.find_each(&:touch)`
class Api::V1::BookTocsRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::BookTocRepresenter
end
