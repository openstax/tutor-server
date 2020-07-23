module CourseMembership
  class InactivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_inactive,
                  message: 'Student is already inactive') if student.dropped?

      student.destroy
      student.send :clear_association_cache
      transfer_errors_from(student, { type: :verbatim }, true)

      RefundPayment.perform_later(uuid: student.uuid) if student.is_refund_allowed

      Lms::Models::CourseScoreCallback.where(
        profile: student.role.profile,
        course: student.course,
      ).destroy_all

      period_id = student.period.id
      queue = student.course.is_preview ? :preview : :dashboard
      task_plan_ids = Tasks::Models::Task.joins(:taskings).where(
        taskings: { entity_role_id: student.entity_role_id }
      ).pluck(:tasks_task_plan_id).compact.uniq
      Tasks::UpdateTaskPlanCaches.set(queue: queue).perform_later(task_plan_ids: task_plan_ids)

      outputs.student = student

      # TODO deactive cohort memberships
    end
  end
end
