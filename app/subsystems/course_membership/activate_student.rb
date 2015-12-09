module CourseMembership
  class ActivateStudent
    lev_routine outputs: { student: :_self }

    def exec(student:)
      fatal_error(code: :already_active) if student.active?
      student.activate.save
      transfer_errors_from(student, { type: :verbatim }, true)
      set(student: student)
    end
  end
end
