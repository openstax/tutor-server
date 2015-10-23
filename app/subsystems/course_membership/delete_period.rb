module CourseMembership
  class DeletePeriod
    lev_routine express_output: :deleted

    protected
    def exec(period:)
      outputs.deleted = period.to_model.destroy
      outputs.errors = period.to_model.errors
    end
  end
end
