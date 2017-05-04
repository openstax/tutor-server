# If role_id provided:
#   make sure it belongs to user; fatal :invalid_role if not
#   teachers can choose roles belonging to any student in their course (impersonation)
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

  uses_routine GetUserCourseRoles, as: :get_user_course_roles
  uses_routine UserIsCourseTeacher, as: :user_is_course_teacher
  uses_routine CourseMembership::GetCourseRoles, as: :get_course_roles

  protected

  def exec(user:, course:, role_id: nil, allowed_role_type: :any)
    # Don't include the user's own inactive student roles
    roles = run(:get_user_course_roles, courses: course, user: user, types: allowed_role_type,
                                        include_inactive_students: false).outputs.roles
    integer_role_id = Integer(role_id) rescue nil

    if integer_role_id
      if run(:user_is_course_teacher, user: user, course: course).outputs.user_is_course_teacher
        # Teacher is allowed to impersonate students
        roles += run(:get_course_roles, course: course, types: :student,
                                        include_inactive_students: true).outputs.roles
      end

      roles = roles.select { |r| r.id == integer_role_id }.uniq

      fatal_error(
        code:    :invalid_role,
        message: "The user does not have the specified role in the course"
      ) if roles.empty?
    end

    case allowed_role_type
    when :any
      unless find_unique_role(roles: roles, type: :teacher)
        unless find_unique_role(roles: roles, type: :student)
          fatal_error(
            code:    :invalid_user,
            message: "The user does not have the any role in the course"
          )
        end
      end
    when :teacher
      unless find_unique_role(roles: roles, type: :teacher)
        fatal_error(
          code:    :invalid_user,
          message: "The user does not have any teacher roles in the course"
        )
      end
    when :student
      unless find_unique_role(roles: roles, type: :student)
        fatal_error(
          code:    :invalid_user,
          message: "The user does not have any student roles in the course"
        )
      end
    else
      fatal_error(
        code: :invalid_argument,
        message: ":allowed_role_type must be one of {:any, :teacher, :student}" +
                 " (was #{allowed_role_type.inspect} instead)"
      )
    end
  end

  protected

  def find_unique_role(roles:, type:)
    matching_roles = roles.select do |role|
      case type
      when :teacher
        role.teacher?
      when :student
        role.student?
      end
    end

    if matching_roles.count > 1
      fatal_error(
        code:    :multiple_roles,
        message: "The user has multiple #{type} roles in the course" +
                 " (specify role to narrow selection)"
      )
    end

    outputs.role = matching_roles.first

    outputs.role.present?
  end
end
