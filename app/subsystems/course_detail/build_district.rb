module CourseDetail
  class BuildDistrict
    lev_routine express_output: :district

    protected
    def exec
      outputs[:district] = Models::District.new
    end
  end
end
