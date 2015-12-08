class GetUserCourses

  lev_routine outputs: { courses: { name: CourseMembership::GetRoleCourses, as: :get_role_courses },
                         roles: { name: Role::GetUserRoles, as: :get_user_roles } }

  protected

  def exec(user:, types: :any)
    run(:get_user_roles, user)
    run(:get_role_courses, roles: result.roles, types: types)
  end
end
