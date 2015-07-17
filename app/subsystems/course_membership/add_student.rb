# Adds the given role to the given period
class CourseMembership::AddStudent
  lev_routine express_output: :student

  protected

  def exec(period:, role:)
    course_periods = period.course.periods.to_a
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error(
      code: :already_a_student, message: "The provided role is already a student in #{
        student.period.course.profile.try(:name) || 'some course'
      }."
    ) unless student.nil?

    outputs[:student] = CourseMembership::Models::Student.new(role: role, course: period.course)
    outputs[:student].enrollments << CourseMembership::Models::Enrollment.new(
      student: outputs[:student], period: period.to_model
    )
    outputs[:student].save
    transfer_errors_from(outputs[:student], type: :verbatim)
  end
end
