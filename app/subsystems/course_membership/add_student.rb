# Adds the given role to the given period
class CourseMembership::AddStudent
  lev_routine express_output: :student

  uses_routine CourseMembership::AddEnrollment,
               as: :add_enrollment,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(period:, role:, student_identifier: nil, assign_published_period_tasks: true)
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error(
      code: :already_a_student, message: "The provided role is already a student in #{
        student.course.name || 'some course'
      }."
    ) unless student.nil?

    student = CourseMembership::Models::Student.create(role: role, course: period.course,
                                                       student_identifier: student_identifier)
    transfer_errors_from(student, {type: :verbatim}, true)

    run(:add_enrollment, period: period, student: student,
                         assign_published_period_tasks: assign_published_period_tasks)
  end
end
