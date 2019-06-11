# If role provided and has an allowed type:
#   Make sure it belongs to user
#   Fatal error :user_not_in_course_with_required_role otherwise
#
# If role is not specified (nil) or does not have an allowed type:
#   Get the user's set of roles for the given course, restricted to allowed_role_types
#   If there are no roles, fail with :user_not_in_course_with_required_role
#   Otherwise return the oldest role of the allowed types
class ChooseCourseRole
  lev_routine express_output: :role

  uses_routine GetUserCourseRoles, as: :get_user_course_roles

  protected

  def exec(user:, course:, current_roles_hash:,
           allowed_role_types: [ :teacher, :student, :teacher_student ])
    selected_role_id = current_roles_hash[course.id.to_s]
    selected_role = user.roles.find_by(id: selected_role_id) unless selected_role_id.nil?

    # Don't include the user's own inactive student/teacher roles
    roles = run(
      :get_user_course_roles, courses: course, user: user, types: allowed_role_types
    ).outputs.roles.sort_by(&:created_at)
    outputs.role = roles.include?(selected_role) ? selected_role : roles.first

    return unless outputs.role.nil?

    fatal_error(
      code:    :user_not_in_course_with_required_role,
      message: "The user does not have the required role in the course"
    )
  end
end
