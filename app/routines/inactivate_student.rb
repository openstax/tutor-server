class InactivateStudent
  lev_routine express_output: :student

  def exec(student:)
    fatal_error(code: :already_inactive) unless student.active?
    student.inactivate.save
    transfer_errors_from(student, { type: :verbatim }, true)
    outputs[:student] = student
  end
end
