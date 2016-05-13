class PropagateTaskPlanUpdates

  lev_routine

  protected

  def updated_attributes_for(tasking_plan:)
    task_plan = tasking_plan.task_plan
    {
      title: task_plan.title,
      description: task_plan.description,
      opens_at: tasking_plan.read_attribute(:opens_at),
      due_at: tasking_plan.read_attribute(:due_at),
      feedback_at: task_plan.is_feedback_immediate ? nil : tasking_plan.read_attribute(:due_at)
    }
  end

  def exec(task_plan:)

    # For now we only handle tasking_plans that point to periods
    task_plan.tasking_plans.each do |tasking_plan|
      period = tasking_plan.target
      raise 'Cannot propagate plan changes for plan not assigned to a period' \
        unless period.is_a?(CourseMembership::Models::Period)

      task_plan.tasks.joins(:taskings).where(taskings: { course_membership_period_id: period.id })
                     .update_all(updated_attributes_for(tasking_plan: tasking_plan))
    end

    task_plan.tasks.reset
  end

end
