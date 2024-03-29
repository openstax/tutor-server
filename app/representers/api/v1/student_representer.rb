module Api::V1
  class StudentRepresenter < SharedRoleRepresenter
    property :uuid,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :course_membership_period_id,
             as: :period_id,
             type: String,
             writeable: true,
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

    property :latest_enrollment_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s(latest_enrollment_at) },
             schema_info: { required: true }

    property :is_active,
             writeable: false,
             readable: true,
             getter: ->(*) { !dropped? },
             schema_info: {
                required: true,
                description: 'Student is dropped if false'
             }

    property :prompt_student_to_pay,
             writeable: false,
             readable: true,
             getter: ->(*) {
               # Shenanigans because sometimes this representer gets an AR, sometimes a hash
               course = self.course || CourseProfile::Models::Course.find(course_profile_course_id)

               Settings::Payments.payments_enabled &&
               course.does_cost &&
               !course.is_preview &&
               !(is_paid || is_comped)
             },
             schema_info: {
               required: true,
               type: 'boolean',
               description: "True if payments enabled globally, course costs and not preview, and not paid or comped"
             }

    property :is_paid,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                type: 'boolean',
                description: "True if student has paid"
             }

    property :is_comped,
             writeable: false,
             readable: true,
             schema_info: {
                required: true,
                type: 'boolean',
                description: "True if student has been comped"
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
                description: "True if the student has a refund in progress"
             }

    property :is_refund_allowed,
             writeable: false,
             readable: true,
             schema_info: {
                type: 'boolean',
                description: "True if the student can currently request a refund"
             }

    property :payment_code,
             writeable: false,
             readable: true,
             if: ->(*) { !payment_code.blank? },
             getter: ->(*) do
              { code: payment_code.code, redeemed_at: payment_code.redeemed_at.to_s }
             end,
             schema_info: {
               description: "Redemption details if payment was via a bookstore code"
             }
  end
end
