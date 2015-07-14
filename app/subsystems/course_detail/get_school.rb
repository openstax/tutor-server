module CourseDetail
  class GetSchool
    lev_routine express_output: :school

    protected
    def exec(id:)
      outputs.school = Models::School.find(id)
    end
  end
end
