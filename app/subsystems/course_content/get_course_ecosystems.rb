class CourseContent::GetCourseEcosystems
  lev_routine express_output: :ecosystems

  protected

  def exec(course:, strategy_class: Content::Strategies::Direct::Ecosystem)
    course_ecosystems = CourseContent::Models::CourseEcosystem.where(course: course.id)
    outputs[:ecosystems] = course_ecosystems.map do |ce|
      content_ecosystem = ce.ecosystem
      strategy = strategy_class.new(ce.ecosystem)
      ::Content::Ecosystem.new(strategy: strategy)
    end
  end
end
