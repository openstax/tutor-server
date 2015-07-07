module Api::V1
  class CourseGuideChildrenRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: CourseGuideChildRepresenter
  end
end
