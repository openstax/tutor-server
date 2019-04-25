class UserIsCourseStudent
  lev_routine

  uses_routine CourseMembership::IsCourseStudent,
               translations: { outputs: { map: { is_course_student: :user_is_course_student } } }

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
