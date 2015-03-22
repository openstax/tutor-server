class GetUserCourseEvents

  lev_routine

  uses_routine GetCourseTaskPlans, as: :get_plans
  uses_routine SearchTasks,        as: :get_tasks
  uses_routine Role::GetUserRoles, as: :get_user_roles

  protected

  def exec(course:, user:)
    roles = Domain::GetUserCourseRoles.call(course: course, user: user, types: [:teacher]).outputs.roles
    outputs[:plans] = roles.empty? ? [] :
                        run(:get_plans, course: course).outputs.items
    outputs[:tasks] = run(:get_tasks, q: "user_id:#{user.id}").outputs.items.to_a
  end

end
