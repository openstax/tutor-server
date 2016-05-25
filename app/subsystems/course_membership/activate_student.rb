module CourseMembership
  class ActivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_active) unless student.deleted?
      student.restore
      student.clear_association_cache
      transfer_errors_from(student, { type: :verbatim }, true)
      outputs[:student] = student
    end
  end
end
