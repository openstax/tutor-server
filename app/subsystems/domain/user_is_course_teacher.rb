class Domain::UserIsCourseTeacher
  lev_routine

  uses_routine Role::GetUserRoles, translations: {type: :verbatim}
  uses_routine CourseMembership::IsCourseTeacher, translations: {type: :verbatim}

  protected

  def exec(user:, course:)
    roles = run(Role::GetUserRoles, user).outputs.roles
    result = run(CourseMembership::IsCourseTeacher,roles: roles, course: course)
    outputs[:user_is_course_teacher] = result.outputs.is_course_teacher
  end
end
