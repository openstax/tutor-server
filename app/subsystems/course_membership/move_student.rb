# Moves the given role to a new period
# Don't use until UX figures out what they want as behavior/warnings
class CourseMembership::MoveStudent
  lev_routine

  protected

  def exec(role:, period:)
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error(code: :not_a_student,
                message: 'The provided role is not a student in any course') if student.nil?

    student.period = period
    student.save
    transfer_errors_from(student, {type: :verbatim}, true)
  end
end
