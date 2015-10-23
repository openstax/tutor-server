module CourseMembership
  class DeletePeriod
    lev_routine

    protected
    def exec(period:)
      period.to_model.destroy
    end
  end
end
