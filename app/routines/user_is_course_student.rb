class UserIsCourseStudent
  lev_query uses: [Role::GetUserRoles, CourseMembership::IsCourseStudent]

  protected
  def query(user:, course:)
    roles = run(:role_get_user_roles, user).roles
    run(:course_membership_is_course_student, roles: roles, course: course)
  end
end
