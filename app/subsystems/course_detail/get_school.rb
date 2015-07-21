module CourseDetail
  class GetSchool
    lev_routine express_output: :school

    protected
    def exec(id:)
      if id != 0 # webforms weirdness
        outputs.school = Models::School.find(id)
      end
    end
  end
end
