# If role_id provided:
#   make sure it belongs to user; fatal :invalid_role if not
#
# If role_id is not specified:
#   Get the users set of roles for the given course, restricted to
#   allowed_role_type unless that is set to :any (the default)
#
#   If there are no roles, fail with :invalid_user
#
#   If there is one role, return it
#
#   If there are multiple roles:
#     If one is a :teacher, return it
#     Otherwise fail with fatal_error code: multiple_roles
#
class ChooseCourseRole

  lev_routine express_output: :role

  uses_routine GetUserCourseRoles

  protected

  def exec(user:, course:, allowed_role_type: :any, role_id: nil)
    user_course_roles = GetUserCourseRoles[
      course: course,
      user:   user,
      types:  allowed_role_type
    ]

    if role_id
      user_course_roles = user_course_roles.select{|role| role.id == Integer(role_id)}
      if user_course_roles.none?
        fatal_error(
          code:    :invalid_role,
          message: "The user does not have the specified role in the course"
        )
      end
    end

    case allowed_role_type
    when :any
      unless find_unique_role(course: course, roles: user_course_roles, type: :teacher)
        unless find_unique_role(course: course, roles: user_course_roles, type: :student)
          fatal_error(
            code:    :invalid_user,
            message: "The user does not have the any role in the course"
          )
        end
      end
    when :teacher
      unless find_unique_role(course: course, roles: user_course_roles, type: :teacher)
        fatal_error(
          code:    :invalid_user,
          message: "The user does not have any teacher roles in the course"
        )
      end
    when :student
      unless find_unique_role(course: course, roles: user_course_roles, type: :student)
        fatal_error(
          code:    :invalid_user,
          message: "The user does not have any student roles in the course"
        )
      end
    else
      fatal_error(
        code: :invalid_argument,
        message: ":allowed_role_type must be one of {:any, :teacher, :student} (not #{allowed_role_type})"
      )
    end
  end

  private

  def find_unique_role(course:, roles:, type:)
    role_name = "#{type.to_s}"
    method_name = "#{role_name}?"
    matching_roles = roles.select do |role|
      case type
      when :teacher
        CourseMembership::IsCourseTeacher[course: course, roles: role]
      when :student
        CourseMembership::IsCourseStudent[course: course, roles: role]
      end
    end
    if matching_roles.count > 1
      fatal_error(
        code:    :multiple_roles,
        message: "The user has multiple #{role_name} roles in the course (specifiy role to narrow selection)"
      )
    end

    found_it = (matching_roles.count == 1)
    outputs[:role] = matching_roles.first if found_it

    found_it
  end

end
