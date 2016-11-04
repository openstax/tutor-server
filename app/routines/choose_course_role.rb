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

  uses_routine GetUserCourseRoles,
    translations: { outputs: { type: :verbatim } },
    as: :get_roles

  protected

  def exec(user:, course:, allowed_role_type: :any, role_id: nil)
    # Don't include the user's own inactive student roles
    run(:get_roles, course: course, user: user, types: allowed_role_type,
                    include_inactive_students: false)
    integer_role_id = Integer(role_id) rescue nil

    if integer_role_id
      extra_roles = get_course_student_roles(course: course, user: user)
      outputs.roles = (outputs.roles + extra_roles).select{ |r| r.id == integer_role_id }.uniq
      fatal_error(
        code:    :invalid_role,
        message: "The user does not have the specified role in the course"
      ) if outputs.roles.none?
    end

    case allowed_role_type
    when :any
      unless find_unique_role(course: course, type: :teacher)
        unless find_unique_role(course: course, type: :student)
          fatal_error(
            code:    :invalid_user,
            message: "The user does not have the any role in the course"
          )
        end
      end
    when :teacher
      unless find_unique_role(course: course, type: :teacher)
        fatal_error(
          code:    :invalid_user,
          message: "The user does not have any teacher roles in the course"
        )
      end
    when :student
      unless find_unique_role(course: course, type: :student)
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

  def find_unique_role(course:, type:)
    matching_roles = outputs.roles.select do |role|
      case type
      when :teacher
        CourseMembership::IsCourseTeacher[course: course, roles: role]
      when :student
        CourseMembership::IsCourseStudent[course: course, roles: role, include_dropped: true]
      end
    end

    if matching_roles.count > 1
      fatal_error(
        code:    :multiple_roles,
        message: "The user has multiple #{type} roles in the course (specifiy role to narrow selection)"
      )
    end

    outputs[:role] = matching_roles.first

    outputs[:role].present?
  end

  def get_course_student_roles(course:, user:)
    # Return student roles if user is a teacher
    user_roles = Role::GetUserRoles.call(user).outputs[:roles]
    is_teacher = CourseMembership::IsCourseTeacher[course: course, roles: user_roles]
    if is_teacher
      # Teachers can impersonate any student, even inactive ones
      CourseMembership::GetCourseRoles.call(course: course, types: :student,
                                            include_inactive_students: true).outputs[:roles]
    else
      []
    end
  end
end
