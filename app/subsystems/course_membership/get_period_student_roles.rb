class CourseMembership::GetPeriodStudentRoles
  lev_routine outputs: { roles: :_self }

  protected
  def exec(periods:, include_inactive_students: false)
    periods = [periods].flatten.uniq

    set(roles: periods.flat_map do |period|
      period.student_roles(include_inactive_students: include_inactive_students)
    end.uniq)
  end
end
