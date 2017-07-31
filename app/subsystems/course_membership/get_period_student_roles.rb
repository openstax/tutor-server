class CourseMembership::GetPeriodStudentRoles
  lev_routine express_output: :roles

  protected

  def exec(periods:, include_dropped_students: false)
    periods = [periods].flatten.uniq

    outputs.roles = periods.flat_map do |period|
      period.student_roles(include_dropped_students: include_dropped_students)
    end.uniq
  end
end
