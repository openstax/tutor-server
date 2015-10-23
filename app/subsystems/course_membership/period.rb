module CourseMembership
  class Period < Entity

    wraps CourseMembership::Models::Period

    exposes :course, :name, :student_roles, :teacher_roles, :enrollment_code, :valid?,
      :errors

    def to_model
      repository
    end

  end
end
