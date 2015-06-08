class CourseMembership::GetStudents
  lev_routine

  protected

  def exec(course)
    outputs[:students] = CourseMembership::Models::Student
                           .includes(:role)
                           .where(course: course)
                           .collect(&:role)
  end
end
