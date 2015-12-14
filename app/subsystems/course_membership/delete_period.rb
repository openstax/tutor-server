module CourseMembership
  class DeletePeriod
    lev_routine outputs: { is_deleted: :_self }

    protected
    def exec(period:)
      set(is_deleted: period.to_model.destroy)
      transfer_errors_from(period.to_model, { type: :verbatim }, false)
    end
  end
end
