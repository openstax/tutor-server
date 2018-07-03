# NOTE: Will save the given course if it is a new record
class CourseContent::AddEcosystemToCourse

  lev_routine express_output: :ecosystem_map, use_jobba: true

  protected

  def exec(course:, ecosystem:,
           ecosystem_strategy_class: ::Content::Strategies::Direct::Ecosystem,
           map_strategy_class: ::Content::Strategies::Generated::Map)
    fatal_error(code: :ecosystem_already_set,
                message: 'The given ecosystem is already active for the given course') \
      if course.lock!.ecosystem.try!(:id) == ecosystem.id

    ecosystem = Content::Ecosystem.new(strategy: ecosystem.wrap) \
      if ecosystem.is_a?(Content::Models::Ecosystem)

    course_ecosystem = CourseContent::Models::CourseEcosystem.new(
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

    if course.new_record?
      # Saving is necessary so the course can be sent to Biglearn
      # because we cannot serialize unsaved AR objects
      course.save
    else
      # Recalculate all TaskPageCaches since we need to map them to the new ecosystem
      all_task_ids = Tasks::Models::Task
        .joins(taskings: { role: :student })
        .where(taskings: { role: { student: { course_profile_course_id: course.id } } })
        .pluck(:id)

      queue = course.is_preview ? :lowest_priority : :low_priority
      all_task_ids.each_slice(100) do |task_ids|
        Tasks::UpdateTaskCaches.set(queue: queue)
                               .perform_later(task_ids: task_ids, queue: queue.to_s)
      end
    end

    OpenStax::Biglearn::Api.prepare_and_update_course_ecosystem(course: course)
  end

end
