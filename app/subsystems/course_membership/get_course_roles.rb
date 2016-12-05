class CourseMembership::GetCourseRoles
  lev_routine express_output: :roles

  uses_routine CourseMembership::GetCourseTeacherRoles, as: :get_course_teacher_roles
  uses_routine CourseMembership::GetPeriodStudentRoles, as: :get_period_student_roles

  protected

  def exec(course:, types: :any, include_inactive_students: false)
    types = [types].flatten
    types = [:teacher, :student, :teacher_student] if types.include?(:any)

    teacher_roles = types.include?(:teacher) ?
                      run(:get_course_teacher_roles, course: course).outputs.roles : []
    student_roles = types.include?(:student) ?
                      run(:get_period_student_roles,
                          periods: course.periods,
                          include_inactive_students: include_inactive_students).outputs.roles : []
    teacher_student_roles = types.include?(:teacher_student) ?
                              course.periods.map(&:teacher_student_role) : []

    outputs.roles = teacher_roles + student_roles + teacher_student_roles
  end
end
