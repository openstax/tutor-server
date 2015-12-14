class GetCourseTeacherUsers
  lev_routine outputs: { teachers: :_self },
              uses: [{ name: CourseMembership::GetTeachers, as: :get_teachers },
                     { name: Role::GetUsersForRoles, as: :get_users }]

  protected

  def exec(course)
    teacher_roles = run(:get_teachers, course).teachers
    set(teachers: run(:get_users, teacher_roles).users)
  end
end
