class PropagateTaskPlanUpdates

  lev_routine

  protected

  def exec(task_plan:)
    task_plan.tasks.update_all(title: task_plan.title, description: task_plan.description)

    # For now we only handle tasking_plans that point to periods
    task_plan.tasking_plans.each do |tasking_plan|
      period = tasking_plan.target
      next unless period.is_a?(CourseMembership::Models::Period)

      feedback_at = task_plan.type == 'homework' ? tasking_plan.due_at : Time.now

      task_plan.tasks.joins(:taskings).where(taskings: { course_membership_period_id: period.id })
                     .update_all(opens_at: tasking_plan.opens_at,
                                 due_at: tasking_plan.due_at,
                                 feedback_at: feedback_at)
    end

    task_plan.tasks.reset
  end

end
