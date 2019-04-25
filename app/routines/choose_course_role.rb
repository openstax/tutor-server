# If role provided:
#   make sure it belongs to user; fatal :user_not_in_course_with_required_role if not
#
# If role is not specified (nil):
#   Get the users set of roles for the given course, restricted to allowed_role_types
#
#   If there are no roles, fail with :user_not_in_course_with_required_role
#
#   If there is one role, return it
#
#   If there are multiple roles:
#     If exactly one is a :teacher, return it
#     If none are teachers and exactly one is a :student, return it
#     Otherwise fail with fatal_error code: multiple_roles
#
class ChooseCourseRole
  lev_routine express_output: :role

  uses_routine GetUserCourseRoles, as: :get_user_course_roles

  protected

  def exec(user:, course:, role:, allowed_role_types: [:teacher, :student, :teacher_student])
    # Don't include the user's own inactive student/teacher roles
    if role.nil?
      roles = run(:get_user_course_roles, courses: course, user: user, types: allowed_role_types)
                .outputs.roles.to_a
    elsif user.id == role.profile.id
      roles = [ role ]
    else
      roles = []
    end

    outputs.role = nil

    allowed_role_types = [ allowed_role_types ].flatten
    allowed_role_types.each do |type|
      matching_roles = roles.select { |role| role.send "#{type}?" }

      if matching_roles.length > 1
        fatal_error(
          code:    :multiple_roles,
          message: "The user has multiple #{type} roles in the course" +
                   " (specify role id to narrow selection)"
        )
      end

      outputs.role = matching_roles.first

      return unless outputs.role.nil?
    end

    fatal_error(
      code:    :user_not_in_course_with_required_role,
      message: "The user does not have the required role in the course"
    )
  end
end
