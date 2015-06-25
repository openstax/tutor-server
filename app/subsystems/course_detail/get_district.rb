module CourseDetail
  class GetDistrict
    lev_routine express_output: :district

    protected
    def exec(id:, action: :read, caller:)
      district = Models::District.find(id)

      raise SecurityTransgression unless DistrictAccessPolicy.action_allowed?(
        action, caller, district
      )

      outputs[:district] = district
    end
  end
end
