module CourseMembership
  class ArchivePeriod
    lev_routine express_output: :period

    def exec(period:)
      fatal_error(
        code: :period_is_already_deleted, message: 'Period is already archived'
      ) if period.archived?

      period.destroy
      period.send :clear_association_cache
      transfer_errors_from(period, { type: :verbatim }, true)
      outputs.period = period

      period.students.each do |student|
        RefundPayment.perform_later(uuid: student.uuid) if student.is_refund_allowed
      end
    end
  end
end
