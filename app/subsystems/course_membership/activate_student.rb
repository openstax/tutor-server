module CourseMembership
  class ActivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_active,
                  message: 'Student is already active') unless student.dropped?

      student.restore
      student.send :clear_association_cache
      transfer_errors_from(student, { type: :verbatim }, true)

      OpenStax::Biglearn::Api.update_rosters(course: student.course)

      period = student.period
      ReassignPublishedPeriodTaskPlans[period: student.period]

      queue = student.course.is_preview ? :preview : :dashboard
      task_plan_ids = Tasks::Models::Task.joins(:taskings).where(
        taskings: { entity_role_id: student.entity_role_id }
      ).pluck(:tasks_task_plan_id).compact.uniq
      Tasks::UpdateTaskPlanCaches.set(queue: queue).perform_later(task_plan_ids: task_plan_ids)

      outputs.student = student

      # TODO reactivate cohort memberships (check with research)
    end
  end
end
