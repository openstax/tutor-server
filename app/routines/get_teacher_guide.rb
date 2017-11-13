class GetTeacherGuide

  include CourseGuideRoutine

  uses_routine CourseMembership::GetPeriodStudentRoles, as: :get_period_student_roles

  protected

  def exec(role:)
    periods = role.teacher.course.periods
    roles = run(
      :get_period_student_roles,
      periods: periods,
      include_dropped_students: false
    ).outputs.roles
    students = roles.map(&:student)

    outputs.course_guide = get_course_guide(students: students, type: :teacher)
  end

end
