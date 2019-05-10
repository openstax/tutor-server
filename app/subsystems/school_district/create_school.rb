module SchoolDistrict
  class CreateSchool
    lev_routine express_output: :school

    protected

    def exec(name:, district: nil)
      outputs.school = ::SchoolDistrict::Models::School.create(name: name, district: district)

      transfer_errors_from(outputs.school, {type: :verbatim}, true)
    end

  end
end
