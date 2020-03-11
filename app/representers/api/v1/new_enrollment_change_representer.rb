module Api::V1
  class NewEnrollmentChangeRepresenter < Roar::Decorator
    include Roar::JSON

    property :enrollment_code,
             type: String,
             readable: false,
             writeable: true,
             setter: ->(fragment:, **) do
               self.enrollment_code = URI.decode_www_form_component fragment
             end,
             schema_info: { required: true }

    property :book_uuid,
             type: String,
             readable: false,
             writeable: true
  end
end
