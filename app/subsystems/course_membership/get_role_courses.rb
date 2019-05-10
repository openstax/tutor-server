# Returns the CourseProfile::Models::Courses for the provided roles (a single role or an array
# of roles) and limited to the type of membership, :all, :student, or :teacher,
# given as an individual symbol or an array of symbols

class CourseMembership::GetRoleCourses

  lev_routine express_output: :courses

  protected

  def exec(roles:, types: :any, include_dropped_students: false,
           include_deleted_teachers: false, preload: nil)
    types = [types].flatten
    if types.include?(:any)
      includes_student = true
      includes_teacher = true
      includes_teacher_student = true
    else
      includes_student = types.include?(:student)
      includes_teacher = types.include?(:teacher)
      includes_teacher_student = types.include?(:teacher_student)
    end

    return outputs.courses = CourseProfile::Models::Course.none \
      unless includes_student || includes_teacher

    role_ids = [roles].flatten.map(&:id)
    subqueries = []
    if includes_student
      student_subquery = CourseProfile::Models::Course
        .joins(:periods)
        .joins(CourseMembership::Models::Enrollment.latest_join_sql(:periods, :student))
        .where(course_membership_students: { entity_role_id: role_ids })

      student_subquery = student_subquery.where(
        periods: { archived_at: nil },
        course_membership_students: { dropped_at: nil }
      ) unless include_dropped_students

      subqueries << student_subquery
    end

    if includes_teacher
      teacher_subquery = CourseProfile::Models::Course
        .joins(:teachers)
        .where(teachers: { entity_role_id: role_ids })

      teacher_subquery = teacher_subquery.where(
        teachers: { deleted_at: nil }
      ) unless include_deleted_teachers

      subqueries << teacher_subquery
    end

    if includes_teacher_student
      teacher_student_subquery = CourseProfile::Models::Course
        .joins(:teacher_students)
        .where(teacher_students: { entity_role_id: role_ids })

      teacher_student_subquery = teacher_student_subquery.where(
        teacher_students: { deleted_at: nil }
      ) unless include_deleted_teachers

      subqueries << teacher_student_subquery
    end

    subquery = "(#{subqueries.map(&:to_sql).join(' UNION ')}) AS \"course_profile_courses\""
    courses = CourseProfile::Models::Course.from(subquery)

    courses = courses.preload(*[preload].flatten) unless preload.nil?

    outputs.courses = courses
  end

end
