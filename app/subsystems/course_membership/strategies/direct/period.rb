class CourseMembership::Strategies::Direct::Period < Entitee

  wraps CourseMembership::Models::Period

  exposes :course, :name,
          :student_roles, :teacher_roles,
          :teacher_student_roles,
          :enrollment_code, :enrollment_code_for_url,
          :archived_at, :archived?, :num_enrolled_students

  def to_model
    repository
  end

  def assignments_count
    repository.assignments_count
  end

end
