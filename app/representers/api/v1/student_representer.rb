module Api::V1
  class StudentRepresenter < Roar::Decorator

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

    property :deidentifier,
             type: String,
             writeable: false,
             readable: true

    property :active?,
             as: :is_active,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                description: "Student is dropped iff false"
             }

  end
end
