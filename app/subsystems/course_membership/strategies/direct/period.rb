class CourseMembership::Strategies::Direct::Period < Entity

  wraps CourseMembership::Models::Period

  exposes :course, :name, :student_roles, :teacher_roles, :enrollment_code, :deleted_at,
          :default_open_time, :default_due_time, :enrollment_code_for_url, :deleted?

  def to_model
    repository
  end

end
