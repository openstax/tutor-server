module Api::V1
  class EnrollmentChangeRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :from_period,
             as: :from,
             decorator: Api::V1::Enrollment::PeriodWithCourseRepresenter,
             readable: true,
             writeable: false

    property :to_period,
             as: :to,
             decorator: Api::V1::Enrollment::PeriodWithCourseRepresenter,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :status,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :requires_enrollee_approval?,
             as: :requires_enrollee_approval,
             readable: true,
             writeable: false,
             schema_info: { required: true, type: 'boolean' }

  end
end
