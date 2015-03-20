class Api::V1::CoursesRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::CourseRepresenter
end
