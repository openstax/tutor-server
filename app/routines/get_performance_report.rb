class GetPerformanceReport

  lev_routine outputs: { performance_report: :_self },
    uses: [{ name: Tasks::GetTpPerformanceReport, as: :get_tp_performance_report },
           { name: Tasks::GetCcPerformanceReport, as: :get_cc_performance_report }]

  protected

  def exec(course:, role:)
    raise(SecurityTransgression, 'The caller is not a teacher in this course') \
      unless CourseMembership::IsCourseTeacher.call(course: course, roles: [role])

    report = course.is_concept_coach ? run(:get_cc_performance_report, course: course) :
                                       run(:get_tp_performance_report, course: course)

    set(performance_report: report.performance_report)
  end
end
