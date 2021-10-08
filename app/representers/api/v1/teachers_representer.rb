module Api::V1
  class TeachersRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: TeacherRepresenter
  end
end
