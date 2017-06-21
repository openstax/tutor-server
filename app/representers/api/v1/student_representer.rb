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

    property :student_identifier,
             type: String,
             writeable: false,
             readable: true

    property :is_active,
             writeable: false,
             readable: true,
             getter: ->(*) { !deleted? },
             schema_info: {
                required: true,
                description: "Student is dropped iff false"
             }

    property :prompt_student_to_pay,
             writeable: false,
             readable: true,
             getter: ->(*) {
               # Shenanigans b/c sometimes this representer gets an AR, sometimes a hash
               course = self.course || CourseProfile::Models::Course.find(course_profile_course_id)

               Settings::Payments.payments_enabled &&
               course.does_cost &&
               !course.is_preview &&
               !(is_paid || is_comped)
             },
             schema_info: {
               required: true,
               type: 'boolean',
               description: "True iff payments enabled globally, course costs and not preview, and not paid or comped"
             }

    property :is_paid,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                type: 'boolean',
                description: "True iff student has paid"
             }

    property :is_comped,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                type: 'boolean',
                description: "True iff student has been comped"
             }

    property :first_paid_at,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(first_paid_at) },
             schema_info: {
                description: "First time the student paid, doesn't change after set"
             }

    property :payment_due_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(payment_due_at) },
             schema_info: {
               description: "Payment is due before this date (if the course costs)"
             }

    property :is_refund_pending,
             writeable: false,
             readable: true,
             schema_info: {
                type: 'boolean',
                description: "True iff the student has a refund in progress"
             }

    property :is_refund_allowed,
             writeable: false,
             readable: true,
             schema_info: {
                type: 'boolean',
                description: "True iff the student can currently request a refund"
             }
  end
end
