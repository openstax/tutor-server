module CourseMembership
  class ArchivePeriod
    lev_routine express_output: :period

    def exec(period:)
      fatal_error(code: :period_is_already_deleted,
                  message: 'Period is already archived') if period.archived?

      period_model = period.to_model
      period_model.destroy
      period_model.send :clear_association_cache
      transfer_errors_from(period_model, { type: :verbatim }, true)
      outputs.period = period

      OpenStax::Biglearn::Api.update_rosters(course: period.course)

      period.to_model.students.each do |student|
        RefundPayment.perform_later(uuid: student.uuid) if student.is_refund_allowed
      end
    end
  end
end
