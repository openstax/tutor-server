module Api::V1
  class CourseRoleRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, readable: true, schema_info: { required: true }

    property :type, readable: true, schema_info: { required: true }

    property :course_id

    property :course_url, readable: true, getter: ->(*) do
      "/api/v1/courses/#{course_id}/role/#{id}"
    end
  end
end
