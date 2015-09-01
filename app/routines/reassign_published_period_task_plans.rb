class ReassignPublishedPeriodTaskPlans

  lev_routine

  uses_routine DistributeTasks, as: :distribute

  protected

  def exec(period:)
    published_task_plans = Tasks::Models::TaskPlan
      .joins(:tasking_plans)
      .preload(:tasking_plans)
      .where(tasking_plans: { target_id: period.id,
                              target_type: 'CourseMembership::Models::Period'})
      .where{ published_at != nil }

    published_task_plans.each{ |tp| run(:distribute, tp) }
  end

end
