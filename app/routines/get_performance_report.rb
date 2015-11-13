class GetPerformanceReport

  lev_routine express_output: :performance_report

  uses_routine Tasks::GetTpPerformanceReport,
               as: :get_tp_performance_report,
               translations: { outputs: { type: :verbatim } }
  uses_routine Tasks::GetCcPerformanceReport,
               as: :get_cc_performance_report,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(course:, role:)
    raise(SecurityTransgression, 'The caller is not a teacher in this course') \
      unless CourseMembership::IsCourseTeacher[course: course, roles: [role]]

    course.is_concept_coach ? run(:get_cc_performance_report, course: course) : \
                              run(:get_tp_performance_report, course: course)
  end
end
