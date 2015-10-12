class GetCourseTaskPlans

  lev_routine

  protected

  def exec(course:, include_trouble_flags: false)
    outputs[:plans] = Tasks::Models::TaskPlan.where(owner: course)
    return unless include_trouble_flags

    outputs[:trouble_plan_ids] = Set.new Tasks::Models::TaskPlan
      .joins(tasks: [:taskings, tasked_exercises: :exercise])
      .group([:id,
              {tasks: {taskings: :course_membership_period_id}},
              {tasks: {tasked_exercises: {exercise: :content_page_id}}}])
      .having{
        (sum(tasks.completed_exercise_steps_count) > sum(tasks.exercise_steps_count)/4) & \
        (sum(tasks.correct_exercise_steps_count) < sum(tasks.completed_exercise_steps_count)/2)
      }.distinct.pluck(:id)
  end

end
