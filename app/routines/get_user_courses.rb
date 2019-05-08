class GetUserCourses

  lev_routine express_output: :courses

  uses_routine CourseMembership::GetRoleCourses,
               as: :get_role_courses,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(user:, types: :any, preload: nil)
    outputs.roles = user.roles
    run(:get_role_courses, roles: outputs.roles, types: types, preload: preload)
  end
end
