class CourseMembership::GetCourseRoles
  lev_routine

  uses_routine CourseMembership::GetPeriodRoles, as: :get_period_roles,
                                                 translations: { outputs: { type: :verbatim } }

  protected

  def exec(course:, types: :any)
    run(:get_period_roles, periods: course.periods, types: types)
  end
end
