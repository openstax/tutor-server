module CourseDetail
  class DeleteDistrict
    lev_routine

    uses_routine GetDistrict

    protected
    def exec(id:, caller:)
      district = GetDistrict[id: id, action: :delete, caller: caller]
      district.destroy
    end
  end
end
