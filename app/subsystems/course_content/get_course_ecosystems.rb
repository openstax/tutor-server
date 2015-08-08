class CourseContent::GetCourseEcosystems
  lev_routine express_output: :ecosystems

  protected

  def exec(course:, strategy_class: Ecosystem::Strategies::Direct::Ecosystem)
    course_ecosystems = CourseContent::Models::CourseEcosystem.where(course: course.id)
    outputs[:ecosystems] = course_ecosystems.collect do |ce|
      content_ecosystem = ce.ecosystem
      strategy = strategy_class.new(ce.ecosystem)
      ::Ecosystem::Ecosystem.new(strategy: strategy)
    end
  end
end
