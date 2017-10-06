class CourseMembership::Strategies::Direct::Period < Entitee

  wraps CourseMembership::Models::Period

  exposes :course, :name,
          :student_roles, :teacher_roles,
          :teacher_student_role, :entity_teacher_student_role_id,
          :default_open_time, :default_due_time,
          :enrollment_code, :enrollment_code_for_url,
          :deleted_at, :deleted?

  def to_model
    repository
  end

  def assignments_count
    repository.assignments_count
  end

end
