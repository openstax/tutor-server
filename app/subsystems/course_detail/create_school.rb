module CourseDetail
  class CreateSchool
    lev_routine express_output: :school

    protected
    def exec(name: 'Unnamed', district_id: nil)
      Models::School.create(name: name, course_detail_district_id: district_id)
    end
  end
end
