module SchoolDistrict
  class CreateSchool
    lev_routine express_output: :school

    uses_routine ::SchoolDistrict::ProcessDistrictChange, as: :process_district_change

    protected

    def exec(name:, district: nil)
      outputs.school = ::SchoolDistrict::Models::School.create(name: name, district: district)

      transfer_errors_from(outputs.school, {type: :verbatim}, true)

      run(:process_district_change, school: outputs.school)
    end

  end
end
