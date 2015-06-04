class CourseMembership::GetCourseRoles
  lev_routine

  uses_routine GetPeriodRoles, as: :get_period_roles

  protected

  def exec(course:, types: :any)
    roles = course.periods.collect do |period|
      run(:get_period_roles, period: period, types: types).outputs.roles
    end

    outputs[:roles] = roles.flatten
  end
end
