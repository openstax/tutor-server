class GetCourseTaskPlans

  lev_routine

  protected

  def exec(course:)
    task_plans = TaskPlan.where(owner: course).to_a
    outputs[:total_count] = task_plans.count
    outputs[:items] = task_plans
  end

end
