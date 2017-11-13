module CourseMembership
  class UnarchivePeriod
    lev_routine express_output: :period

    def exec(period:)
      fatal_error(code: :period_is_not_deleted,
                  message: 'Period is already active') unless period.archived?
      period_model = period.to_model
      period_model.restore
      period_model.clear_association_cache
      transfer_errors_from(period_model, { type: :verbatim }, true)
      outputs.period = period

      OpenStax::Biglearn::Api.update_rosters(course: period.course)
    end
  end
end
