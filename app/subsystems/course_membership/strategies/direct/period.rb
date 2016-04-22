class CourseMembership::Strategies::Direct::Period < Entity

  wraps CourseMembership::Models::Period

  exposes :course, :name, :student_roles, :teacher_roles, :enrollment_code,
          :default_open_time, :default_due_time

  def to_model
    repository
  end

end
