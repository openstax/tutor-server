# If role provided:
#   make sure it belongs to user; fatal :user_not_in_course_with_required_role if not
#
# If role is not specified (nil):
#   Get the user's set of roles for the given course, restricted to allowed_role_types
#
#   If there are no roles, fail with :user_not_in_course_with_required_role
#
#   Otherwise return the oldest role
#
class ChooseCourseRole
  lev_routine express_output: :role

  uses_routine GetUserCourseRoles, as: :get_user_course_roles

  protected

  def exec(user:, course:, role:, allowed_role_types: [:teacher, :student, :teacher_student])
    # Don't include the user's own inactive student/teacher roles
    if role.nil?
      roles = run(:get_user_course_roles, courses: course, user: user, types: allowed_role_types)
                .outputs.roles.sort_by(&:created_at)
    elsif user.id == role.profile.id
      roles = [ role ]
    else
      roles = []
    end

    allowed_role_types = [ allowed_role_types ].flatten.map(&:to_s)
    outputs.role = roles.find { |role| allowed_role_types.include? role.role_type }

    return unless outputs.role.nil?

    fatal_error(
      code:    :user_not_in_course_with_required_role,
      message: "The user does not have the required role in the course"
    )
  end
end
