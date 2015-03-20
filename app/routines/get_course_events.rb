class GetCourseEvents

  lev_routine

  uses_routine GetCourseTaskPlans, as: :get_plans
  uses_routine SearchTasks,        as: :get_tasks

  protected

  def exec(course:, user:)
    outputs[:plans] = run(:get_plans, course: course).outputs.items
    # Call to_a to convert from an AR::Association to array so it matches :plans
    outputs[:tasks] = run(:get_tasks, q: "user_id:#{user.id}").outputs.items.to_a
  end

end
