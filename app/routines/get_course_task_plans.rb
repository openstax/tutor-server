class GetCourseTaskPlans

  lev_routine

  protected

  def exec(course:, include_trouble_flags: false)
    outputs[:plans] = Tasks::Models::TaskPlan.where(owner: course)
    return unless include_trouble_flags

    outputs[:trouble_plan_ids] = Set.new Tasks::Models::TaskPlan.joins(:tasks).group(:id).having{
      (sum(tasks.completed_exercise_steps_count) > sum(tasks.exercise_steps_count)/4) & \
      (sum(tasks.correct_exercise_steps_count) < sum(tasks.completed_exercise_steps_count)/2)
    }.pluck(:id)
  end

end
