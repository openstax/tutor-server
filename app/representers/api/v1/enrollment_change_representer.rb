module Api::V1
  class EnrollmentChangeRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :student_identifier,
             type: String,
             readable: true,
             writeable: false

    property :from_period,
             as: :from,
             extend: Api::V1::Enrollment::PeriodWithCourseRepresenter,
             # If the previous period is archived, then the enrollment is
             # considered a fresh join, and "from" shouldn't be included
             if: ->(*) { from_period.try!(:deleted?) == false },
             readable: true,
             writeable: false

    property :to_period,
             as: :to,
             extend: Api::V1::Enrollment::PeriodWithCourseRepresenter,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :conflicting_period,
             as: :conflict,
             extend: Api::V1::Enrollment::PeriodWithCourseRepresenter,
             # If the conflicting period is archived,
             # or ends before the period we are switching to,
             # we suppress the conflict message
             if: ->(*) { conflicting_period.try!(:deleted?) == false &&
                         conflicting_period.course.ends_at >= to_period.course.ends_at },
             readable: true,
             writeable: false

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
