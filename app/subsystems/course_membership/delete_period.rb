module CourseMembership
  class DeletePeriod
    lev_routine express_output: :is_deleted

    protected
    def exec(period:)
      outputs.is_deleted = period.to_model.destroy
      transfer_errors_from(period.to_model, { type: :verbatim }, false)
    end
  end
end
