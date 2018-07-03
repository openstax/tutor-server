class GetCourseEcosystemsMap
  lev_routine express_output: :ecosystems_map

  protected

  def exec(course:, ecosystem_strategy_class: ::Content::Strategies::Direct::Ecosystem,
                    map_strategy_class: ::Content::Strategies::Generated::Map)
    to_content_ecosystem = course.ecosystem

    raise 'The given course has no ecosystems' if to_content_ecosystem.nil?

    to_ecosystem_strategy = ecosystem_strategy_class.new(to_content_ecosystem)
    to_ecosystem = ::Content::Ecosystem.new(strategy: to_ecosystem_strategy)

    course_ecosystems = course.ecosystems
    tp_ecosystem_ids = Tasks::Models::TaskPlan.where(owner: course).uniq
                                              .pluck(:content_ecosystem_id)
    tp_ecosystems = Content::Models::Ecosystem.where(id: tp_ecosystem_ids)

    from_ecosystems = (course_ecosystems + tp_ecosystems).uniq.map do |from_content_ecosystem|
      from_ecosystem_strategy = ecosystem_strategy_class.new(from_content_ecosystem)
      ::Content::Ecosystem.new(strategy: from_ecosystem_strategy)
    end

    map_attributes = { from_ecosystems: from_ecosystems,
                       to_ecosystem: to_ecosystem,
                       strategy_class: map_strategy_class }

    outputs[:ecosystems_map] = ::Content::Map.find_or_create_by(map_attributes)
  end
end
