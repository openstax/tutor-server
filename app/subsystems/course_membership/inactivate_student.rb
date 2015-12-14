module CourseMembership
  class InactivateStudent
    lev_routine outputs: { student: :_self }

    def exec(student:)
      fatal_error(code: :already_inactive) unless student.active?
      student.inactivate.save
      transfer_errors_from(student, { type: :verbatim }, true)
      set(student: student)
    end
  end
end
