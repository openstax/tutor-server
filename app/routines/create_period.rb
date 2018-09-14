class CreatePeriod
  lev_routine express_output: :period

  uses_routine CourseMembership::CreatePeriod, translations: { outputs: { type: :verbatim } },
                                               as: :create_period

  uses_routine Tasks::AssignCoursewideTaskPlansToNewPeriod, as: :assign_coursewide_task_plans

  def exec(course:, name: nil, enrollment_code: nil, uuid: nil)
    run(:create_period, course: course, name: name, enrollment_code: enrollment_code, uuid: uuid)
    run(:assign_coursewide_task_plans, period: outputs.period)
  end
end
