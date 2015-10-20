class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name:)
    period = CourseMembership::Models::Period.create(course: course, name: name)
    Tasks::Models::TaskingPlan.where(target: course.periods).each do |tasking_plan|
      Tasks::Models::TaskingPlan.create(
        target: period,
        opens_at: tasking_plan.opens_at,
        due_at: tasking_plan.due_at,
        tasks_task_plan_id: tasking_plan.tasks_task_plan_id
      )
    end
    transfer_errors_from(period, {type: :verbatim}, true)
    outputs[:period] = CourseMembership::Period.new(period)
  end
end
