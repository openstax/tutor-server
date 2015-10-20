class CreatePeriod
  lev_routine express_output: :period

  uses_routine CourseMembership::CreatePeriod,
    translations: { outputs: { type: :verbatim } },
    as: :create_period

  uses_routine Tasks::AssignCoursewideTaskingPlans,
    as: :assign_coursewide_tasking_plans

  def exec(course:, name: nil)
    name ||= (course.periods.count + 1).ordinalize
    run(:create_period, course: course, name: name)
    run(:assign_coursewide_tasking_plans, period: outputs.period)
  end
end
