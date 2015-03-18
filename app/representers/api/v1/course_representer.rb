module Api::V1
  class CourseRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :name,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    collection :roles,
      extend: Api::V1::RoleRepresenter,
      readable: true,
      writable: false,
      schema_info: {
        required: false
      }

  end
end
