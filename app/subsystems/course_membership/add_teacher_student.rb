# Adds the given role to the given period
class CourseMembership::AddTeacherStudent
  lev_routine express_output: :teacher_student

  protected

  def exec(period:, role:, reassign_published_period_task_plans: true, send_to_biglearn: true)
    teacher_student = CourseMembership::Models::TeacherStudent.find_by role: role, deleted_at: nil
    fatal_error(
      code: :already_a_student, message: "The provided role is already a student in #{
        teacher_student.course.name || 'some course'
      }."
    ) unless teacher_student.nil?

    course = period.course

    teacher_student = CourseMembership::Models::TeacherStudent.create(role: role,
                                                                      course: course,
                                                                      period: period)
    transfer_errors_from(teacher_student, { type: :verbatim }, true)

    ReassignPublishedPeriodTaskPlans.perform_later(period: period) \
      if reassign_published_period_task_plans

    OpenStax::Biglearn::Api.update_rosters(course: period.course) if send_to_biglearn
  end
end
