class GetCourseEcosystem
  lev_routine outputs: { ecosystem: :_self }

  protected

  def exec(course:, strategy_class: ::Content::Strategies::Direct::Ecosystem)
    if course.ecosystems.any?
      # The first ecosystem is the latest
      strategy = strategy_class.new(course.ecosystems.first)
      set(ecosystem: ::Content::Ecosystem.new(strategy: strategy))
    else
      set(ecosystem: nil)
    end
  end
end
