class UserIsCourseStudent
  lev_routine

  uses_routine Role::GetUserRoles, translations: { outputs: { type: :verbatim } }
  uses_routine CourseMembership::IsCourseStudent,
               translations: { outputs: { map: { is_course_student: :user_is_course_student } } }

  protected

  def exec(user:, course:, include_dropped: false, include_archived: false)
    run(Role::GetUserRoles, user)
    run(CourseMembership::IsCourseStudent,
        roles: outputs.roles,
        course: course,
        include_dropped: include_dropped,
        include_archived: include_archived)
  end
end
