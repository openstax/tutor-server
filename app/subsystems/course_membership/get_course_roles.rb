class CourseMembership::GetCourseRoles
  lev_routine express_output: :roles

  uses_routine CourseMembership::GetCourseTeacherRoles, as: :get_course_teacher_roles
  uses_routine CourseMembership::GetPeriodStudentRoles, as: :get_period_student_roles

  protected

  def exec(course:, types: :any, include_dropped_students: false, include_archived_periods: false)
    types = [types].flatten
    types = [:teacher, :student, :teacher_student] if types.include?(:any)

    periods = include_archived_periods ? course.periods : course.periods.without_deleted

    teacher_roles = types.include?(:teacher) ?
                      run(:get_course_teacher_roles, course: course).outputs.roles : []
    student_roles = types.include?(:student) ?
                      run(:get_period_student_roles,
                          periods: periods,
                          include_dropped_students: include_dropped_students).outputs.roles : []
    teacher_student_roles = types.include?(:teacher_student) ?
                              periods.map(&:teacher_student_role) : []

    outputs.roles = teacher_roles + student_roles + teacher_student_roles
  end
end
