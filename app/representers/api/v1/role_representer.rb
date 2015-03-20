module Api::V1
  class RoleRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id,
             type: Integer,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :course_url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }
  end
end
