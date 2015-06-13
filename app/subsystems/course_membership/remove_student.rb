# Removes the given role from its period/course
# Don't use until UX figures out what they want as behavior/warnings
class CourseMembership::RemoveStudent
  lev_routine

  protected

  def exec(role:)
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error(code: :not_a_student,
                message: 'The provided role is not a student in any course') if student.nil?

    student.destroy
  end
end
