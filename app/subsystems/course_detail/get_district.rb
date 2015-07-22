module CourseDetail
  class GetDistrict
    lev_routine express_output: :district

    protected
    def exec(id:)
      if !id.blank? && id != 0 # webforms weirdness
        outputs.district = Models::District.find(id)
      end
    end
  end
end
