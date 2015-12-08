# Adds the given student to the given period
class CourseMembership::AddEnrollment
  lev_routine outputs: {
                enrollment: :_self,
                student: :_self
              },
              uses: { name: ReassignPublishedPeriodTaskPlans,
                      as: :reassign_period_task_plans }

  protected
  def exec(period:, student:)
    set(enrollment: CourseMembership::Models::Enrollment.create(
      student: student, period: period.to_model
    ))

    transfer_errors_from(result.enrollment, {type: :verbatim}, true)

    student.enrollments << result.enrollment
    student.activate.save! unless student.active?
    set(student: student)

    ReassignPublishedPeriodTaskPlans.perform_later(period: period.to_model)
  end
end
