module Api::V1
  class CourseRoleRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, readable: true, schema_info: { required: true }

    property :type, readable: true, schema_info: { required: true }

    property :course_id, readable: true
  end
end
