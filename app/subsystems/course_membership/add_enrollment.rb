# Adds the given student to the given period
class CourseMembership::AddEnrollment

  lev_routine

  protected

  def exec(period:, student:, reassign_published_period_task_plans: true, send_to_biglearn: true)
    outputs[:enrollment] = CourseMembership::Models::Enrollment.create(
      student: student, period: period.to_model
    )
    transfer_errors_from(outputs[:enrollment], {type: :verbatim}, true)

    student.enrollments << outputs[:enrollment]
    student.restore if student.deleted?
    outputs[:student] = student
    transfer_errors_from(outputs[:student], {type: :verbatim}, true)

    ReassignPublishedPeriodTaskPlans.perform_later(period: period.to_model) \
      if reassign_published_period_task_plans

    OpenStax::Biglearn::Api.update_rosters(course: period.course) if send_to_biglearn
  end
end
