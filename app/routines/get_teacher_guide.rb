class GetTeacherGuide

  include CourseGuideRoutine

  uses_routine CourseMembership::GetPeriodStudentRoles, as: :get_period_student_roles

  protected

  def get_course_guide(role)
    course = role.teacher.course

    roles_by_period = {}
    course.periods.each do |period|
      roles_by_period[period] = run(:get_period_student_roles, periods: period,
                                    include_inactive_students: false).outputs.roles
    end

    all_roles = roles_by_period.values.flatten
    history = get_history_for_roles(all_roles)
    ecosystems_map = get_course_ecosystems_map(course)

    course.periods.map do |period|
      period_roles = roles_by_period[period]

      get_period_guide(period, period_roles, history, ecosystems_map, :teacher)
    end
  end

end
