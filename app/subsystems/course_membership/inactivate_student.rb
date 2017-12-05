module CourseMembership
  class InactivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_inactive,
                  message: 'Student is already inactive') if student.dropped?
      student.destroy
      student.clear_association_cache
      transfer_errors_from(student, { type: :verbatim }, true)

      OpenStax::Biglearn::Api.update_rosters(course: student.course)

      RefundPayment.perform_later(uuid: student.uuid) if student.is_refund_allowed

      period = student.period
      Tasks::UpdatePeriodCaches.perform_later(periods: period) unless period.nil?

      outputs.student = student
    end
  end
end
