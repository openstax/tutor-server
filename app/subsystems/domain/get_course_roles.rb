class Domain::GetCourseRoles
  lev_routine

  uses_routine CourseMembership::GetCourseRoles,
               translations: { outputs: { type: :verbatim } },
               as: :get_course_roles

  protected

  def exec(course:, user:)
    run(:get_course_roles, course: course, user: user)
  end
end
