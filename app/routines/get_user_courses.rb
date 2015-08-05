class GetUserCourses

  lev_routine express_output: :courses

  uses_routine Role::GetUserRoles,
               as: :get_user_roles,
               translations: { outputs: { type: :verbatim } }

  uses_routine CourseMembership::GetRoleCourses,
               as: :get_role_courses,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, types: :any)
    run(:get_user_roles, user)
    run(:get_role_courses, roles: outputs.roles, types: types)
  end
end
