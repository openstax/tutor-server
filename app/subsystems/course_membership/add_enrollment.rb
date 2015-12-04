# Adds the given student to the given period
class CourseMembership::AddEnrollment

  lev_routine

  protected

  def exec(period:, student:)
    outputs[:enrollment] = CourseMembership::Models::Enrollment.create(
      student: student, period: period.to_model
    )
    transfer_errors_from(outputs[:enrollment], {type: :verbatim}, true)

    student.enrollments << outputs[:enrollment]
    student.activate.save! unless student.active?
    outputs[:student] = student

    ReassignPublishedPeriodTaskPlans.perform_later(period: period.to_model)
  end
end
