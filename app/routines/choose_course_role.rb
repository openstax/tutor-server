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
  lev_routine outputs: { role: :_self,
                         roles: :_self,
                         _verbatim: { name: GetUserCourseRoles, as: :get_roles } }

  protected

  def exec(user:, course:, allowed_role_type: :any, role_id: nil)
    run(:get_roles, course: course, user: user, types: allowed_role_type,
                    include_inactive_students: false)

    if role_id
      extra_roles = get_course_student_roles(course: course, user: user)
      roles = result.roles.select { |r| r.id == Integer(role_id) } +
                extra_roles.select { |r| r.id == Integer(role_id) }

      set(roles: roles.uniq)

      if result.roles.none?
        fatal_error(
          code:    :invalid_role,
          message: "The user does not have the specified role in the course"
        )
      end
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
    matching_roles = result.roles.select do |role|
      case type
      when :teacher
        CourseMembership::IsCourseTeacher.call(course: course, roles: role)
      when :student
        CourseMembership::IsCourseStudent.call(course: course, roles: role)
      end
    end

    if matching_roles.count > 1
      fatal_error(
        code:    :multiple_roles,
        message: "The user has multiple #{type} roles in the course (specifiy role to narrow selection)"
      )
    end

    found_it = (matching_roles.count == 1)
    set(role: matching_roles.first) if found_it

    found_it
  end

  def get_course_student_roles(course:, user:)
    # Return student roles if user is a teacher
    user_roles = Role::GetUserRoles.call(user).roles
    is_teacher = CourseMembership::IsCourseTeacher.call(course: course, roles: user_roles)
    if is_teacher
      # Teachers can impersonate any student, even inactive ones
      CourseMembership::GetCourseRoles.call(course: course, types: :student,
                                            include_inactive_students: true).roles
    else
      []
    end
  end
end
