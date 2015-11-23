class UserIsCourseStudent
  lev_routine outputs: {
    _verbatim: Role::GetUserRoles,
    is_course_student: CourseMembership::IsCourseStudent
  }

  protected
  def exec(user:, course:)
    run(:role_get_user_roles, user)
    run(:course_membership_is_course_student, roles: result.roles, course: course)
  end
end
