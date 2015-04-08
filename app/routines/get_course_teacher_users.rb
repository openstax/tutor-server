class Domain::GetCourseTeacherUsers
  lev_routine

  uses_routine CourseMembership::GetTeachers, translations: {outputs: {map: {teachers: :teacher_roles}}}
  uses_routine Role::GetUsersForRoles,        translations: {outputs: {map: {users: :teachers}}}

  protected

  def exec(course)
    run(CourseMembership::GetTeachers, course)
    run(Role::GetUsersForRoles, outputs[:teacher_roles])
  end
end
