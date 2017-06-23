class GetCourseEcosystem
  lev_routine transaction: :no_transaction, express_output: :ecosystem

  protected

  def exec(course:, strategy_class: ::Content::Strategies::Direct::Ecosystem)
    # The first ecosystem is the latest
    content_ecosystem = course.ecosystems.first

    if content_ecosystem.nil?
      outputs[:ecosystem] = nil
      return
    end

    strategy = strategy_class.new(content_ecosystem)
    outputs[:ecosystem] = ::Content::Ecosystem.new(strategy: strategy)
  end
end
