# Returns Roles belonging to a User in one or many Courses.
#
# Parameters:
#
#   courses: a Course or an array of Courses
#   user: a User
#   types: can be `:student`, `:teacher`, `:any` or an array including one or more of these symbols
#
class GetUserCourseRoles
  lev_routine express_output: :roles

  protected

  def exec(user:, courses:, types: :any, include_inactive_students: false, preload: nil)
    types = [types].flatten
    if types.include?(:any)
      includes_student = true
      includes_teacher = true
    else
      includes_student = types.include?(:student)
      includes_teacher = types.include?(:teacher)
    end

    return outputs.roles = Entity::Role.none unless includes_student || includes_teacher

    course_ids = [courses].flatten.map(&:id)
    subqueries = []
    if includes_student
      student_subquery = Entity::Role
        .select('entity_roles.*, course_membership_students.course_profile_course_id')
        .joins(:student)
        .joins(
          <<-SQL.strip_heredoc
            INNER JOIN #{CourseMembership::Models::Enrollment.with_reverse_sequence_number_sql}
              ON course_membership_enrollments.course_membership_student_id =
                course_membership_students.id
            INNER JOIN course_membership_periods
              ON course_membership_periods.id =
                course_membership_enrollments.course_membership_period_id
          SQL
        )
        .where(course_membership_periods: { course_profile_course_id: course_ids })

      student_subquery = student_subquery
        .where(student: { deleted_at: nil },
               course_membership_periods: { deleted_at: nil }) unless include_inactive_students

      subqueries << student_subquery
    end

    if includes_teacher
      subqueries << Entity::Role
        .select('entity_roles.*, course_membership_teachers.course_profile_course_id')
        .joins(:teacher)
        .where(teacher: { course_profile_course_id: course_ids })
    end

    subquery = subqueries.size == 1 ? subqueries.first.arel : subqueries.reduce(:union)

    # http://radar.oreilly.com/2014/05/more-than-enough-arel.html
    role_table = Entity::Role.arel_table
    roles = Entity::Role.from(role_table.create_table_alias(subquery, :entity_roles))
                        .joins(:role_user)
                        .where(role_user: { user_profile_id: user.id })

    roles = roles.preload(*[preload].flatten) unless preload.nil?

    outputs.roles = roles
  end
end
