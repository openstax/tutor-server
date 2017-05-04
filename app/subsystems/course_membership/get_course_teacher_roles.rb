class CourseMembership::GetCourseTeacherRoles
  lev_routine express_output: :roles

  protected
  def exec(course:)
    outputs.roles = course.teachers.map(&:role)
  end
end
