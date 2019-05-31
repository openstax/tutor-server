class CourseProfile::MarkCourseEnrolled

  lev_routine

  protected

  def exec(course:)
    course.update_attribute :is_access_switchable, false
    transfer_errors_from(course, { type: :verbatim }, true)
  end

end
