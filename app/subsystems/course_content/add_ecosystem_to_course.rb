class CourseContent::AddEcosystemToCourse

  lev_routine express_output: :ecosystem_map

  protected

  def exec(course:, ecosystem:,
           ecosystem_strategy_class: ::Content::Strategies::Direct::Ecosystem,
           map_strategy_class: ::Content::Strategies::Generated::Map)
    fatal_error(code: :ecosystem_already_set,
                message: 'The given ecosystem is already active for the given course') \
      if course.lock!.ecosystems.first.try!(:id) == ecosystem.id

    ecosystem = Content::Ecosystem.new(strategy: ecosystem.wrap) \
      if ecosystem.is_a?(Content::Models::Ecosystem)

    course_ecosystem = CourseContent::Models::CourseEcosystem.create(
      course: course, content_ecosystem_id: ecosystem.id
    )
    course.course_ecosystems << course_ecosystem
    transfer_errors_from(course_ecosystem, {type: :verbatim}, true)

    # Create a mapping from the old course ecosystems to the new one and validate it
    from_ecosystems = course.course_ecosystems.map do |course_ecosystem|
      strategy = ecosystem_strategy_class.new(course_ecosystem.ecosystem)
      ::Content::Ecosystem.new(strategy: strategy)
    end

    outputs[:ecosystem_map] = ::Content::Map.find_or_create_by!(from_ecosystems: from_ecosystems,
                                                                to_ecosystem: ecosystem,
                                                                strategy_class: map_strategy_class)

    OpenStax::Biglearn::Api.prepare_and_update_course_ecosystem(course: course)
  end

end
