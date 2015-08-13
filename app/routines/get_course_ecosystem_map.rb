class GetCourseEcosystemMap
  lev_routine express_output: :map

  protected

  def exec(course:, ecosystem_strategy_class: ::Content::Strategies::Direct::Ecosystem,
                    map_strategy_class: ::Content::Strategies::Generated::Map)
    # The first ecosystem is the latest
    to_content_ecosystem = course.ecosystems.first
    to_ecosystem_strategy = ecosystem_strategy_class.new(to_content_ecosystem)
    to_ecosystem = ::Content::Ecosystem.new(strategy: to_ecosystem_strategy)

    from_ecosystems = course.ecosystems.collect do |from_content_ecosystem|
      from_ecosystem_strategy = ecosystem_strategy_class.new(from_content_ecosystem)
      ::Content::Ecosystem.new(strategy: from_ecosystem_strategy)
    end

    map_attributes = { from_ecosystems: from_ecosystems,
                       to_ecosystem: to_ecosystem,
                       strategy_class: map_strategy_class }
    map = ::Content::Map.find(map_attributes) || ::Content::Map.create(map_attributes)
    fatal_error(code: :invalid_map,
                message: 'Could not map ecosystems to each other') if map.nil? || !map.valid?

    outputs[:map] = map
  end
end
