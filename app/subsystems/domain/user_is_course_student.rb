class Domain::UserIsCourseStudent
  lev_routine

  uses_routine Role::GetUserRoles, translations: {type: :verbatim}
  uses_routine CourseMembership::IsCourseStudent, translations: {type: :verbatim}

  protected

  def exec(user:, course:)
    roles = run(Role::GetUserRoles, user).outputs.roles
    result = run(CourseMembership::IsCourseStudent,roles: roles, course: course)
    outputs[:user_is_course_student] = result.outputs.is_course_student
  end
end
