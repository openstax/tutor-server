class CourseMembership::Strategies::Direct::Period < Entity

  wraps CourseMembership::Models::Period

  exposes :course, :name,
          :student_roles, :teacher_roles, :teacher_student_role,
          :default_open_time, :default_due_time,
          :enrollment_code, :enrollment_code_for_url,
          :deleted_at, :deleted?

  def to_model
    repository
  end

end
