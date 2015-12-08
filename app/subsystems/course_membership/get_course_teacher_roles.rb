class CourseMembership::GetCourseTeacherRoles
  lev_routine outputs: { roles: :_self }

  protected
  def exec(course:)
    set(roles: course.teachers.map(&:role))
  end
end
