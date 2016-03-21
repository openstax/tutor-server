class PropagateTaskPlanUpdates

  lev_routine

  protected

  def exec(task_plan:)

    # For now we only handle tasking_plans that point to periods
    task_plan.tasking_plans.each do |tasking_plan|

      period = tasking_plan.target
      raise 'Cannot propagate plan changes for plan not assigned to a period' \
        unless period.is_a?(CourseMembership::Models::Period)

          task_plan.assistant.update_tasks_for_plan(tasking_plan: tasking_plan, where: {
                                                    taskings: { course_membership_period_id: period.id }
                                                  })
    end

    task_plan.tasks.reset
  end

end
