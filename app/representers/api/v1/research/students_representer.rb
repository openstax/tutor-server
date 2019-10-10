class Api::V1::Research::StudentsRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::Research::StudentRepresenter
end
