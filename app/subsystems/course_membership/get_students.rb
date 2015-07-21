class CourseMembership::GetStudents
  lev_routine

  protected

  def exec(period:)
    outputs[:students] = period.student_roles
  end
end
