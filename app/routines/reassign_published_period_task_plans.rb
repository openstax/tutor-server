class ReassignPublishedPeriodTaskPlans

  lev_routine

  uses_routine DistributeTasks, as: :distribute

  protected

  def exec(period:, protect_unopened_tasks: true)
    status.set_job_args(period: period.to_global_id.to_s)

    published_task_plans = Tasks::Models::TaskPlan
      .tasked_to_period_id(period.id)
      .published
      .non_withdrawn
      .preload_tasking_plans

    published_task_plans.each_with_index do |tp, ii|
      status.set_progress(ii, published_task_plans.size)
      run(:distribute, task_plan: tp,
                       publish_time: Time.current,
                       protect_unopened_tasks: protect_unopened_tasks)
    end
  end

end
