class Period < Entity

  wraps CourseMembership::Models::Period

  exposes :course, :name

  def student_roles
    repository.students.include(:role).collect{|s| s.role}
  end

  def teacher_roles
    repository.course.teachers.include(:role).collect{|s| s.role}
  end

end
