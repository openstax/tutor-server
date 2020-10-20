class ReassignPublishedPeriodTaskPlans
  lev_routine active_job_enqueue_options: { queue: :reassign }

  protected

  def exec(period:, role: nil, protect_unopened_tasks: true, queue: 'reassign')
    status.set_job_args(period: period.to_global_id.to_s)

    published_task_plans = Tasks::Models::TaskPlan
      .tasked_to_period_id(period.id)
      .published
      .non_withdrawn
      .preload_tasking_plans

    published_task_plans.each_with_index do |tp, ii|
      status.set_progress(ii, published_task_plans.size)
      DistributeTasks.set(queue: queue.to_sym).perform_later(
        task_plan: tp,
        role: role,
        publish_time: Time.current.iso8601,
        protect_unopened_tasks: protect_unopened_tasks
      )
    end
  end
end
