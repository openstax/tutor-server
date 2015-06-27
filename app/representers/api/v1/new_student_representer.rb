module Api::V1
  class NewStudentRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :course_membership_period_id,
             as: :period_id,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               required: true
             }

    property :entity_role_id,
             as: :role_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :email,
             type: String,
             writeable: true,
             readable: true

    property :username,
             type: String,
             writeable: true,
             readable: true

    property :password,
             type: String,
             writeable: true,
             readable: false

    property :first_name,
             type: String,
             writeable: true,
             readable: true

    property :last_name,
             type: String,
             writeable: true,
             readable: true

    property :full_name,
             type: String,
             writeable: true,
             readable: true

  end
end
