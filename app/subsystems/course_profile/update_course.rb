class CourseProfile::UpdateCourse
  lev_routine

  protected

  def exec(id, course_params)
    course = CourseProfile::Models::Course.find_by(id: id)
    course.update_attributes(course_params)

    transfer_errors_from course, {type: :verbatim}, true

    OpenStax::Biglearn::Api.update_rosters course: course
    OpenStax::Biglearn::Api.update_course_active_dates course: course
  end

end
