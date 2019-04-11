class Lms::UnpairCourse

  lev_routine

  def exec(course:)
    unless course.is_access_switchable?
      fatal_error(code: :course_access_is_locked, message: "Course access is locked")
    end
    if course.lms_contexts.any?
      course.lms_contexts.destroy_all
    end
    transfer_errors_from(course, {type: :verbatim})
  end
end
