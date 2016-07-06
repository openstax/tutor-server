module CourseMembership
  class ActivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_active) unless student.deleted?
      student.restore(recursive: true)
      student.clear_association_cache
      transfer_errors_from(student, { type: :verbatim }, true)
      ReassignPublishedPeriodTaskPlans[period: student.period]
      outputs[:student] = student
    end
  end
end
