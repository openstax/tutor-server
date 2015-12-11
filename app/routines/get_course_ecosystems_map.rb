class GetCourseEcosystemsMap
  lev_routine outputs: { ecosystems_map: :_self }

  protected

  def exec(course:, ecosystem_strategy_class: ::Content::Strategies::Direct::Ecosystem,
                    map_strategy_class: ::Content::Strategies::Generated::Map)
    # The first ecosystem is the latest
    to_content_ecosystem = course.ecosystems.preload(
      pages: [ :all_exercises_pool, { chapter: :all_exercises_pool } ]
    ).first

    raise 'The given course has no ecosystems' if to_content_ecosystem.nil?

    to_ecosystem_strategy = ecosystem_strategy_class.new(to_content_ecosystem)
    to_ecosystem = ::Content::Ecosystem.new(strategy: to_ecosystem_strategy)

    from_ecosystems = course.ecosystems.collect do |from_content_ecosystem|
      from_ecosystem_strategy = ecosystem_strategy_class.new(from_content_ecosystem)
      ::Content::Ecosystem.new(strategy: from_ecosystem_strategy)
    end

    map_attributes = { from_ecosystems: from_ecosystems,
                       to_ecosystem: to_ecosystem,
                       strategy_class: map_strategy_class }

    set(ecosystems_map: ::Content::Map.find(map_attributes) || \
                          ::Content::Map.create!(map_attributes))
  end
end
