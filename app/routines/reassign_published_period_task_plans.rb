class ReassignPublishedPeriodTaskPlans

  lev_routine

  uses_routine DistributeTasks, as: :distribute

  protected

  def exec(period:, protect_unopened_tasks: true)
    status.set_job_args(period: period.to_global_id.to_s)

    published_task_plans = Tasks::Models::TaskPlan
      .joins(:tasking_plans)
      .where(tasking_plans: { target_id: period.id,
                              target_type: 'CourseMembership::Models::Period' })
      .where.not(first_published_at: nil )
      .where(withdrawn_at: nil)
      .preload(:tasking_plans)

    published_task_plans.each_with_index do |tp, ii|
      status.set_progress(ii, published_task_plans.size)
      run(:distribute, task_plan: tp,
                       publish_time: Time.current,
                       protect_unopened_tasks: protect_unopened_tasks)
    end
  end

end
