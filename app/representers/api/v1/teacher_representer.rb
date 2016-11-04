module Api::V1
  class TeacherRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :course_profile_course_id,
             as: :course_id,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               required: true
             }

    property :role_id,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { respond_to?(:role_id) ? role_id : entity_role_id },
             schema_info: {
               required: true
             }

    property :first_name,
             type: String,
             writeable: false,
             readable: true

    property :last_name,
             type: String,
             writeable: false,
             readable: true

    property :name,
             type: String,
             writeable: false,
             readable: true

  end
end
