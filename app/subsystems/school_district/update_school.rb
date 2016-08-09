module SchoolDistrict
  class UpdateSchool
    lev_routine express_output: :school

    uses_routine SchoolDistrict::ProcessDistrictChange, as: :process_district_change

    protected

    def exec(school:, name:, district:)
      school.update_attributes(name: name, district: district)

      transfer_errors_from(school, {type: :verbatim})

      outputs.school = school

      run(:process_district_change, school: school)
    end
  end
end
