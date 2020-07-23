module CourseMembership
  class UnarchivePeriod
    lev_routine express_output: :period

    def exec(period:)
      fatal_error(code: :period_is_not_deleted,
                  message: 'Period is already active') unless period.archived?

      period.restore
      period.send :clear_association_cache
      transfer_errors_from(period, { type: :verbatim }, true)
      outputs.period = period
    end
  end
end
