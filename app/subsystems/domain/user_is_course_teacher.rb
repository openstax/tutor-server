class Domain::UserIsCourseTeacher
  lev_routine

  uses_routine RoleSs::GetUserRoles, translations: {type: :verbatim}
  uses_routine CourseSs::IsCourseTeacher, translations: {type: :verbatim}

  protected

  def exec(user:, course:)
    roles = run(RoleSs::GetUserRoles, user).outputs.roles
    result = run(CourseSs::IsCourseTeacher,roles: roles, course: course)
    outputs[:is_course_teacher] = result.outputs.is_course_teacher
  end
end
