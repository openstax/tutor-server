module Api::V1
  class TeacherCourseGuideRepresenter < Roar::Decorator
    include Representable::JSON::Collection
    items extend: CourseGuidePeriodRepresenter
  end
end
