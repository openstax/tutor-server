class CreatePeriod
  lev_routine outputs: {
    _verbatim: { name: CourseMembership::CreatePeriod, as: :create_period }
  },
  uses: { name: Tasks::AssignCoursewideTaskPlansToNewPeriod, as: :assign_coursewide_task_plans }

  def exec(course:, name: nil)
    name ||= (course.periods.count + 1).ordinalize
    run(:create_period, course: course, name: name)
    run(:assign_coursewide_task_plans, period: result.period)
  end
end
