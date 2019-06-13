# Returns all Roles belonging to a User in one or many Courses.
#
# Parameters:
#
#   courses: a Course or an array of Courses
#   user: a User
#   types: can be `:student`, `:teacher`, `:teacher_student`, `:any`
#   or an array including one or more of these symbols
#
class GetUserCourseRoles
  lev_routine express_output: :roles

  protected

  def exec(user:, courses:, types: [:teacher, :student, :teacher_student],
           include_dropped_students: false, include_deleted_teachers: false, preload: nil)
    if user.is_anonymous?
      outputs.roles = user.roles
      return
    end

    types = [types].flatten.map(&:to_sym)
    if types.include?(:any)
      includes_student = true
      includes_teacher = true
      includes_teacher_student = true
    else
      includes_student = types.include?(:student)
      includes_teacher = types.include?(:teacher)
      includes_teacher_student = types.include?(:teacher_student)
    end

    course_ids = [courses].flatten.map(&:id)
    subqueries = []
    er = Entity::Role.arel_table
    if includes_student
      student_subquery = user.roles
        .select(
          er[Arel.star],
          CourseMembership::Models::Student.arel_table[:course_profile_course_id]
        )
        .joins(:student)
        .joins(CourseMembership::Models::Enrollment.latest_join_sql(:student, :period))
        .where(course_membership_periods: { course_profile_course_id: course_ids })

      student_subquery = student_subquery.where(
        student: { dropped_at: nil },
        course_membership_periods: { archived_at: nil }
      ) unless include_dropped_students

      subqueries << student_subquery
    end

    if includes_teacher
      teacher_subquery = user.roles
        .select(
          er[Arel.star],
          CourseMembership::Models::Teacher.arel_table[:course_profile_course_id]
        )
        .joins(:teacher)
        .where(teacher: { course_profile_course_id: course_ids })

      teacher_subquery = teacher_subquery.where(
        teacher: { deleted_at: nil }
      ) unless include_deleted_teachers

      subqueries << teacher_subquery
    end

    if includes_teacher_student
      teacher_student_subquery = user.roles
        .select(
          er[Arel.star],
          CourseMembership::Models::TeacherStudent.arel_table[:course_profile_course_id]
        )
        .joins(:teacher_student)
        .where(teacher_student: { course_profile_course_id: course_ids })

      teacher_student_subquery = teacher_student_subquery.where(
        teacher_student: { deleted_at: nil }
      ) unless include_deleted_teachers

      subqueries << teacher_student_subquery
    end

    subquery = "(#{subqueries.map(&:to_sql).join(' UNION ')}) AS \"#{Entity::Role.table_name}\""
    outputs.roles = Entity::Role.from(subquery)

    outputs.roles = outputs.roles.preload(*[preload].flatten) unless preload.nil?
  end
end
