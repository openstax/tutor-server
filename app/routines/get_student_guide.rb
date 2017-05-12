class GetStudentGuide

  include CourseGuideRoutine

  protected

  def get_course_guide(role)
    period = role.student.period
    course = period.course
    history = get_history_for_roles(role)
    ecosystems_map = get_course_ecosystems_map(course)

    get_period_guide(period, role, history, ecosystems_map, :student)
  end

end
