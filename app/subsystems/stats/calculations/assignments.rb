class Stats::Calculations::Assignments
  lev_routine

  protected

  def exec(stats:, date_range:)
    ts = Tasks::Models::TaskPlan.arel_table

    q = stats.active_populated_courses.dup
      .unscope(:select)
      .joins(:task_plans)
      .select(ts[:id].count.as('counts'))

    outputs.num_task_plans = Tasks::Models::TaskPlan
      .from("(#{q.to_sql}) as task_plans")
      .sum("task_plans.counts").to_i
  end

end
