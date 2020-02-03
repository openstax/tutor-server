module Manager::CourseDetails
  protected

  def get_course_details
    @course = CourseProfile::Models::Course.find(params[:id])
    @periods = @course.periods
    @teachers = @course.teachers
                       .preload(role: { profile: :account })
                       .sort_by { |teacher| teacher.last_name || teacher.name }
    @students = @course.students
                       .preload(role: { profile: :account })
                       .sort_by { |student| student.last_name || student.name }
    @ecosystems = Content::ListEcosystems[]

    @course_ecosystem = @course.ecosystem

    @catalog_offerings = Catalog::ListOfferings[]
  end
end
