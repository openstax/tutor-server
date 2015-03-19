# Returns Roles belonging to a User in a Course.
#
# Parameters:
#
#   course: an Entity::Course
#   user: an Entity::User
#   types: can be `:any` or an array including one
#     or more of `:student`, `:teacher`, `:any`
#
class Domain::GetUserCourseRoles
  lev_routine

  uses_routine Role::GetUserRoles,
               as: :get_user_roles

  uses_routine CourseMembership::Api::GetCourseRoles,
               as: :get_course_roles

  protected

  def exec(course:, user:, types: :any)
    run(:get_user_roles, user)
    run(:get_course_roles, course: course, types: types)

    # Intersect the results from above
    outputs[:roles] = outputs["[:get_user_roles, :roles]"] & 
                      outputs["[:get_course_roles, :roles]"]
  end
end