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

    property :first_name,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :last_name,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :name,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :period_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :role_id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

  end
end
