class Lms::RemoveLastCoursePairing

  lev_routine

  def exec(course:)
    unless course.is_access_switchable?
      fatal_error(code: :course_access_is_locked, message: "Course access is locked")
    end
    if course.lms_contexts.any?
      course.lms_contexts.order(:created_at).last.destroy
    end
    transfer_errors_from(course, {type: :verbatim})
  end
end
