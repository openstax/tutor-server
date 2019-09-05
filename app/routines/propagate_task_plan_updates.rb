class PropagateTaskPlanUpdates

  lev_routine

  protected

  def updated_attributes_for(tasking_plan:)
    task_plan = tasking_plan.task_plan

    # This routine is only called after tasks are open and we do not allow changing the open date
    # after tasks are open. However, it is possible the task_plan is assigned to multiple periods
    # and it is not yet open for all periods, so we must propagate opens_at in that case.
    # TaskPlansController#update already enforces that we don't change open dates for periods
    # whose assignments are already out to students.
    {
      title: task_plan.title,
      description: task_plan.description,
      opens_at_ntz: tasking_plan.opens_at_ntz,
      due_at_ntz: tasking_plan.due_at_ntz,
      feedback_at_ntz: task_plan.is_feedback_immediate ? nil : tasking_plan.due_at_ntz
    }
  end

  def exec(task_plan:)
    # For now we only handle tasking_plans that point to periods
    task_plan.tasking_plans.each do |tasking_plan|
      raise 'Cannot propagate plan changes for plan not assigned to a period' \
        unless tasking_plan.target_type == CourseMembership::Models::Period.name

      task_plan.tasks.joins(:taskings)
                     .where(taskings: { course_membership_period_id: tasking_plan.target_id })
                     .update_all(updated_attributes_for(tasking_plan: tasking_plan))
    end

    task_plan.tasks.reset

    requests = task_plan.tasks.preload(taskings: { role: :student })
                              .map { |task| { course: task_plan.owner, task: task } }
    OpenStax::Biglearn::Api.create_update_assignments(requests)
  end

end
