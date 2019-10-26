class Api::V1::Research::CoursesRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::Research::CourseRepresenter
end
