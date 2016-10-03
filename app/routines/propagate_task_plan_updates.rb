class PropagateTaskPlanUpdates

  lev_routine

  protected

  def updated_attributes_for(tasking_plan:)
    task_plan = tasking_plan.task_plan

    # This routine is only called after tasks are open and
    # we do not allow changing the open date after open
    {
      title: task_plan.title,
      description: task_plan.description,
      due_at_ntz: tasking_plan.due_at_ntz,
      feedback_at_ntz: task_plan.is_feedback_immediate ? nil : tasking_plan.due_at_ntz
    }
  end

  def exec(task_plan:)
    # For now we only handle tasking_plans that point to periods
    task_plan.tasking_plans.each do |tasking_plan|
      period = tasking_plan.target
      raise 'Cannot propagate plan changes for plan not assigned to a period' \
        unless period.is_a?(CourseMembership::Models::Period)

      task_plan.tasks.joins(:taskings)
                     .where(taskings: { course_membership_period_id: period.id })
                     .update_all(updated_attributes_for(tasking_plan: tasking_plan))
    end

    task_plan.tasks.reset

    requests = task_plan.tasks.map{ |task| { task: task } }
    OpenStax::Biglearn::Api.create_update_assignments(requests)
  end

end
