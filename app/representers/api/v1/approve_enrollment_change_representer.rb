module Api::V1
  class ApproveEnrollmentChangeRepresenter < Roar::Decorator

    include Roar::JSON

    property :student_identifier,
             type: String,
             readable: true,
             writeable: true
  end
end
