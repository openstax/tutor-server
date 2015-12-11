class GetCourseTaskPlans

  COMPLETED_TASK_STEPS = Squeel::Nodes::Literal.new 'CASE WHEN tasks_task_steps.first_completed_at IS NULL THEN 0 ELSE 1 END'
  CORRECT_TASKED_EXERCISES = Squeel::Nodes::Literal.new 'CASE WHEN tasks_tasked_exercises.correct_answer_id = tasks_tasked_exercises.answer_id THEN 1 ELSE 0 END'

  lev_routine outputs: { plans: :_self,
                         trouble_plan_ids: :_self }

  protected

  def exec(course:, include_trouble_flags: false)
    set(plans: Tasks::Models::TaskPlan.where(owner: course))
    return unless include_trouble_flags

    set(trouble_plan_ids: result.plans
      .joins(tasks: [:taskings, tasked_exercises: :exercise])
      .group([
        :id,
        {tasks: {taskings: :course_membership_period_id}},
        {tasks: {tasked_exercises: {exercise: :content_page_id}}}
      ]).having{
        (sum(COMPLETED_TASK_STEPS) > count(tasks.tasked_exercises.id)/4) & \
        (sum(CORRECT_TASKED_EXERCISES) < sum(COMPLETED_TASK_STEPS)/2)
      }.distinct.pluck(:id))
  end

end
