class Api::V1::Research::Sparfa::StudentsRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::Research::Sparfa::StudentRepresenter
end
