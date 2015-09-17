class CourseMembership::GetCourseRoles
  lev_routine express_output: :roles

  uses_routine CourseMembership::GetPeriodRoles,
    as: :get_period_roles,
    translations: { outputs: { type: :verbatim } }

  protected

  def exec(course:, types: :any, include_inactive_students: false)
    run(:get_period_roles, periods: course.periods,
                           types: types,
                           include_inactive_students: include_inactive_students)
  end
end
