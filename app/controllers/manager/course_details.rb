module Manager::CourseDetails
  protected

  def get_course_details
    @course = CourseProfile::Models::Course.find(params[:id])
    @teachers = @course.teachers
                       .preload(role: { profile: :account })
                       .sort_by { |teacher| teacher.last_name || teacher.name }
  end
end
