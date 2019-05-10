module SchoolDistrict
  class UpdateSchool
    lev_routine express_output: :school

    protected

    def exec(school:, name:, district:)
      school.update_attributes(name: name, district: district)

      transfer_errors_from(school, {type: :verbatim})

      outputs.school = school
    end
  end
end
