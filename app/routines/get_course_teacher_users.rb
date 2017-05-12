class GetCourseTeacherUsers
  lev_routine

  uses_routine CourseMembership::GetTeachers,
               as: :get_teachers,
               translations: {outputs: {map: {teachers: :teacher_roles}}}
  uses_routine Role::GetUsersForRoles,
               as: :get_users_for_roles,
               translations: {outputs: {map: {users: :teachers}}}

  protected

  def exec(course)
    run(:get_teachers, course)
    run(:get_users_for_roles, outputs.teacher_roles)
  end
end
