module CourseMembership
  class ActivateStudent
    lev_routine express_output: :student

    def exec(student:)
      fatal_error(code: :already_active) if student.active?
      student.activate.save
      transfer_errors_from(student, { type: :verbatim }, true)
      outputs[:student] = student
    end
  end
end
