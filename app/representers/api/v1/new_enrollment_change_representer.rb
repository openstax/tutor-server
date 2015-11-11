module Api::V1
  class NewEnrollmentChangeRepresenter < Roar::Decorator

    include Roar::JSON

    property :enrollment_code,
             type: String,
             readable: false,
             writeable: true,
             schema_info: { required: true }

    property :book_uuid,
             type: String,
             readable: false,
             writeable: true

  end
end
