# Adds the given student to the given period
class CourseMembership::AddEnrollment
  lev_routine

  protected

  def exec(period:, student:, reassign_published_period_task_plans: true)
    enrollment = CourseMembership::Models::Enrollment.new(student: student, period: period)
    student.enrollments << enrollment
    student.update_attribute :period, period
    outputs.enrollment = enrollment
    transfer_errors_from(enrollment, { type: :verbatim }, true)
    student.restore if student.dropped?
    outputs.student = student
    transfer_errors_from(student, { type: :verbatim }, true)

    ReassignPublishedPeriodTaskPlans.perform_later(period: period) \
      if reassign_published_period_task_plans
  end
end
