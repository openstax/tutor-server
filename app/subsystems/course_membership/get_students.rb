class CourseMembership::GetStudents
  lev_routine

  protected

  def exec(period:)
    outputs[:students] = CourseMembership::Models::Student
                           .includes(:role)
                           .where(period: period)
                           .collect(&:role)
  end
end
