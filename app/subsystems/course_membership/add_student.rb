# Adds the given role to the given period
class CourseMembership::AddStudent
  lev_routine

  protected

  def exec(period:, role:)
    course_periods = period.course.periods.to_a
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error(
      code: :already_a_student, message: "The provided role is already a student in #{
        student.period.course.profile.try(:name) || 'some course'
      }."
    ) unless student.nil?

    student = CourseMembership::Models::Student.create(role: role, period: period.to_model)
    transfer_errors_from(student, {type: :verbatim}, true)
  end
end
