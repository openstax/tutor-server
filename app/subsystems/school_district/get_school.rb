module SchoolDistrict
  class GetSchool
    lev_routine express_output: :school

    protected
    def exec(id: nil, name: nil)
      if !id.blank? && id != 0 # webforms weirdness
        outputs.school = Models::School.find(id)
      elsif !name.blank?
        outputs.school = Models::School.where(name: name).first
      end
    end
  end
end
