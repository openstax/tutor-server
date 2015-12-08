# Returns Roles belonging to a User in a Course.
#
# Parameters:
#
#   course: an Entity::Course
#   user: a User::User
#   types: can be `:any` or an array including one
#     or more of `:student`, `:teacher`, `:any`
#
class GetUserCourseRoles
  lev_routine outputs: { roles: :_self },
    uses: [{ name: Role::GetUserRoles, as: :get_user_roles },
           { name: CourseMembership::GetCourseRoles, as: :get_course_roles }]

  protected

  def exec(course:, user:, types: :any, include_inactive_students: false)
    user_roles = run(:get_user_roles, user).roles
    course_roles = run(:get_course_roles, course: course,
                                          types: types,
                                          include_inactive_students: include_inactive_students).roles

    set(roles: user_roles & course_roles)
  end
end
