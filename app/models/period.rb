class Period < Entity

  wraps CourseMembership::Models::Period

  exposes :course, :name, :student_roles, :teacher_roles

  def to_model
    repository
  end

end
