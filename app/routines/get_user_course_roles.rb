# Returns Roles belonging to a User in a Course.
#
# Parameters:
#
#   course: a CourseProfile::Models::Course
#   user: a User::User
#   types: can be `:any` or an array including one
#     or more of `:student`, `:teacher`, `:any`
#
class GetUserCourseRoles
  lev_routine express_output: :roles

  uses_routine Role::GetUserRoles, as: :get_user_roles

  uses_routine CourseMembership::GetCourseRoles, as: :get_course_roles

  protected

  def exec(course:, user:, types: :any, include_inactive_students: false)
    user_roles = run(:get_user_roles, user).outputs.roles
    course_roles = run(:get_course_roles, course: course,
                                          types: types,
                                          include_inactive_students: include_inactive_students)
                     .outputs.roles

    # Intersect the results from above
    outputs[:roles] = user_roles & course_roles
  end
end
