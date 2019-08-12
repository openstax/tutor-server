class UserIsCourseStudent
  lev_routine express_output: :is_course_student

  uses_routine CourseMembership::IsCourseStudent, translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, course:, include_dropped_students: false, include_archived_periods: false)
    outputs.roles = user.roles

    run(CourseMembership::IsCourseStudent,
        roles: outputs.roles,
        course: course,
        include_dropped_students: include_dropped_students,
        include_archived_periods: include_archived_periods)
  end
end
