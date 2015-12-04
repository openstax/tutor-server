class CourseMembership::GetCourseRoles
  lev_routine outputs: { roles: :_self },
              uses: [{ name: CourseMembership::GetCourseTeacherRoles,
                       as: :get_course_teacher_roles },
                     { name: CourseMembership::GetPeriodStudentRoles,
                       as: :get_period_student_roles }]

  protected
  def exec(course:, types: :any, include_inactive_students: false)
    teacher_roles = [:any, :teacher].include?(types) ?
                      run(:get_course_teacher_roles, course: course).roles : []
    student_roles = [:any, :student].include?(types) ?
                      run(:get_period_student_roles,
                          periods: course.periods,
                          include_inactive_students: include_inactive_students).roles : []
    set(roles: teacher_roles + student_roles)
  end
end
