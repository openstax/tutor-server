class PropagateTaskPlanUpdates

  lev_routine

  protected

  def exec(task_plan:)
    task_plan.tasks.update_all(title: task_plan.title, description: task_plan.description)
    task_plan.tasks.reset
  end

end
