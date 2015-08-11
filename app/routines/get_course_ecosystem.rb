class GetCourseEcosystem
  lev_routine express_output: :ecosystem

  protected

  def exec(course:)
    # The first ecosystem is the latest
    content_ecosystem = course.ecosystems.first

    if content_ecosystem.nil?
      outputs[:ecosystem] = nil
      return
    end

    strategy = ::Ecosystem::Strategies::Direct::Ecosystem.new(content_ecosystem)
    outputs[:ecosystem] = ::Ecosystem::Ecosystem.new(strategy: strategy)
  end
end
