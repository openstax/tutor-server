module CourseDetail
  class GetDistrict
    lev_routine express_output: :district

    protected
    def exec(id:)
      outputs.district = Models::District.find(id)
    end
  end
end
