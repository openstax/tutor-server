module Api::V1
  class StudentTeacherUpdateRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :student_identifier,
             type: String,
             writeable: true,
             readable: true,
             schema_info: {
               required: true
             }

  end
end
