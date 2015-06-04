class MoveUserToCoursePeriod
  lev_routine

  uses_routine GetUserCourseRoles
  uses_routine CourseMembership::AddStudent

  protected

  def exec(user:, course:, period_name:)
    roles = run(GetUserCourseRoles, user: user, course: course, types: :student).outputs.roles
    run(CourseMembership::AddStudent, course: course, role: roles.first, period_name: period_name)
  end
end
