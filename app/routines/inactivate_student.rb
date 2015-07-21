class InactivateStudent
  lev_routine express_output: :student

  def exec(student:)
    student.inactivate.save!
    outputs[:student] = student
  end
end
