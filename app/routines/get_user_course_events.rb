class GetUserCourseEvents

  lev_routine

  uses_routine GetCourseTaskPlans, as: :get_plans
  uses_routine GetCourseUserTasks,
               as: :get_tasks,
               translations: { outputs: { type: :verbatim} }
  uses_routine Role::GetUserRoles, as: :get_user_roles

  protected

  def exec(course:, user:)
    roles = GetUserCourseRoles.call(course: course, user: user, types: [:teacher]).outputs.roles
    outputs[:plans] = roles.empty? ? [] :
                        run(:get_plans, course: course).outputs.items
    run(:get_tasks, course: course, user: user)
  end

end
