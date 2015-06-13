module Api::V1
  class StudentsRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: StudentRepresenter
  end
end
