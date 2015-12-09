class UserIsCourseTeacher
  lev_query uses: [Role::GetUserRoles, CourseMembership::IsCourseTeacher]

  protected
  def query(user:, course:)
    roles = run(:role_get_user_roles, user).roles
    run(:course_membership_is_course_teacher, roles: roles, course: course)
  end
end
