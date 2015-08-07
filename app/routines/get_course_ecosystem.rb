class GetCourseEcosystem
  lev_routine express_output: :ecosystem

  protected

  def exec(course:)
    content_ecosystem = course.ecosystems.first
    strategy = Ecosystem::Strategies::Direct::Ecosystem.new(content_ecosystem)
    outputs[:ecosystem] = Ecosystem::Ecosystem.new(strategy: strategy)
  end
end
