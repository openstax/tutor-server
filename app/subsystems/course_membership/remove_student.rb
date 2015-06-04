# Removes the given role from its period/course
class CourseMembership::RemoveStudent
  lev_routine

  protected

  def exec(role:)
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error('The provided role is not a student in any course') if student.nil?

    student.destroy
  end
end
