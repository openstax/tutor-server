# Adds the given student to the given period
class CourseMembership::AddEnrollment

  lev_routine

  protected

  def exec(period:, student:, assign_published_period_tasks: true)
    outputs[:enrollment] = CourseMembership::Models::Enrollment.create(
      student: student, period: period.to_model
    )
    transfer_errors_from(outputs[:enrollment], {type: :verbatim}, true)

    student.enrollments << outputs[:enrollment]
    student.restore if student.deleted?
    outputs[:student] = student
    transfer_errors_from(outputs[:student], {type: :verbatim}, true)

    course = period.course
    OpenStax::Biglearn::Api.update_rosters(course: course) if course.course_ecosystems.any?

    ReassignPublishedPeriodTaskPlans.perform_later(period: period.to_model) \
      if assign_published_period_tasks
  end
end
