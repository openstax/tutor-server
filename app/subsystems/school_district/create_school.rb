module SchoolDistrict
  class CreateSchool
    lev_routine express_output: :school

    protected
    def exec(name:, district: nil)
      outputs.school = Models::School.create(name: name,
                                             school_district_district_id: district.try(:id))

      transfer_errors_from(outputs.school, {type: :verbatim}, true)

      # TODO find a more appropriate home for this
      Legal::MakeChildGetParentContracts[child: outputs.school,
                                         parent: district] if district.present?
    end

  end
end
