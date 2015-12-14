class ReassignPublishedPeriodTaskPlans
  lev_routine uses: DistributeTasks

  protected
  def exec(period:, protect_unopened_tasks: true)
    published_task_plans = Tasks::Models::TaskPlan
      .joins(:tasking_plans)
      .preload(:tasking_plans)
      .where(tasking_plans: { target_id: period.id,
                              target_type: 'CourseMembership::Models::Period'})
      .where{ published_at != nil }

    published_task_plans.each do |tp|
      run(:distribute_tasks, tp, Time.now, protect_unopened_tasks)
    end
  end
end
