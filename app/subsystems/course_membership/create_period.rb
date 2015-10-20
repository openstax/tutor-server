class CourseMembership::CreatePeriod
  lev_routine express_output: :period

  protected

  def exec(course:, name:)
    period = CourseMembership::Models::Period.create(course: course, name: name)
    plans = Tasks::Models::TaskPlan.joins(:tasking_plans)
                           .preload(:tasking_plans)
                           .where(tasking_plans: { target_id: course.periods.flat_map(&:id),
                                                   target_type: 'CourseMembership::Models::Period' })
    binding.pry if plans.any?
    plans.each do |tp|
      Tasks::Models::TaskingPlan.create(
        target: period,
        opens_at: tp.tasking_plans.first.opens_at,
        due_at: tp.tasking_plans.first.due_at,
        tasks_task_plan_id: tp.id
      )
    end
    transfer_errors_from(period, {type: :verbatim}, true)
    outputs[:period] = CourseMembership::Period.new(period)
  end
end
