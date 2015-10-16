class GetCourseMetadata
  lev_routine express_output: :metadata

  uses_routine GetCourseEcosystem, as: :get_course_ecosystem

  protected

  def exec(course:, strategy_class: Content::Strategies::Direct::Ecosystem)

    ecosystem = get_course_ecosystem[course: course, strategy_class: strategy_class]
    debugger
  end
end
