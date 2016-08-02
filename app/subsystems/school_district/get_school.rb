module SchoolDistrict
  class GetSchool
    lev_routine express_output: :school

    protected

    def exec(id: nil, name: nil, district: nil)
      if name.present?
        outputs.school = ::SchoolDistrict::Models::School.find_by(name: name, district: district)
      else
        outputs.school = ::SchoolDistrict::Models::School.find_by(id: id)
      end
    end
  end
end
