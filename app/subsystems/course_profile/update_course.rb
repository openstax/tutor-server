class CourseProfile::UpdateCourse
  lev_routine

  protected

  def exec(id, course_params)
    course = CourseProfile::Models::Course.find_by(id: id)
    course.update_attributes(course_params)

    transfer_errors_from course, { type: :verbatim }, true

    Tasks::Models::Task.where(course: course).find_each(&:update_caches_later) \
      if course.previous_changes['timezone'] ||
         course.previous_changes['past_due_unattempted_ungraded_wrq_are_zero']
  end
end
