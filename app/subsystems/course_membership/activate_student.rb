module CourseMembership
  class ActivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_active,
                  message: 'Student is already active') unless student.dropped?

      student.restore
      student.clear_association_cache
      transfer_errors_from(student, { type: :verbatim }, true)

      OpenStax::Biglearn::Api.update_rosters(course: student.course)

      period = student.period
      ReassignPublishedPeriodTaskPlans[period: student.period]

      queue = student.course.is_preview ? :lowest_priority : :low_priority
      Tasks::UpdatePeriodCaches.set(queue: queue).perform_later(period_ids: period.id, force: true)

      outputs.student = student
    end
  end
end
