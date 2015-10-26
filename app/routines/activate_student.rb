class ActivateStudent
  lev_routine express_output: :student

  def exec(student:)
    student.activate.save
    transfer_errors_from(student, { type: :verbatim }, true)
    outputs[:student] = student
  end
end
