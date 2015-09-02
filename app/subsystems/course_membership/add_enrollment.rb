# Adds the given student to the given period
class CourseMembership::AddEnrollment

  lev_routine

  uses_routine ReassignPublishedPeriodTaskPlans, as: :reassign_period_task_plans

  protected

  def exec(period:, student:)
    outputs[:enrollment] = CourseMembership::Models::Enrollment.create(
      student: student, period: period.to_model
    )
    transfer_errors_from(outputs[:enrollment], {type: :verbatim}, true)

    student.enrollments << outputs[:enrollment]
    student.activate.save! unless student.active?
    outputs[:student] = student

    run(:reassign_period_task_plans, period: period)
  end
end
