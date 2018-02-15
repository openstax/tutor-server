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
    course.is_concept_coach ? run(:get_cc_performance_report, course: course, role: role) : \
                              run(:get_tp_performance_report, course: course, role: role)
  end
end
