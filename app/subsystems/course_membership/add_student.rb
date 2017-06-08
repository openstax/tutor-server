# Adds the given role to the given period
class CourseMembership::AddStudent
  lev_routine express_output: :student

  uses_routine CourseMembership::AddEnrollment,
               as: :add_enrollment,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(period:, role:, student_identifier: nil,
           reassign_published_period_task_plans: true, send_to_biglearn: true)
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error(
      code: :already_a_student, message: "The provided role is already a student in #{
        student.course.name || 'some course'
      }."
    ) unless student.nil?

    course = period.course

    # Give the student til midnight after 14 days from now
    payment_due_at = course.time_zone.to_tz.now.midnight + 1.day - 1.second +
                     Settings::Payments.student_grace_period_days.days

    student = CourseMembership::Models::Student.create(role: role,
                                                       course: course,
                                                       payment_due_at: payment_due_at,
                                                       student_identifier: student_identifier)
    transfer_errors_from(student, {type: :verbatim}, true)

    run(
      :add_enrollment,
      period: period,
      student: student,
      reassign_published_period_task_plans: reassign_published_period_task_plans,
      send_to_biglearn: send_to_biglearn
    )
  end
end
