class GetPerformanceReport

  lev_routine express_output: :performance_report

  uses_routine Tasks::GetPerformanceReport,
               as: :get_performance_report,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(course:, role:)
    raise(SecurityTransgression, 'The caller is not a teacher in this course') \
      unless CourseMembership::IsCourseTeacher[course: course, roles: [role]]

    run(:get_performance_report, course: course)
  end
end
