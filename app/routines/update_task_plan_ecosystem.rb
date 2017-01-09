class UpdateTaskPlanEcosystem

  lev_routine express_output: :task_plan

  protected

  # Note: Does not save the task_plan, that's up to the caller
  def exec(task_plan:, ecosystem:)
    # Lock the plan to prevent concurrent publication
    outputs.task_plan = task_plan.lock!

    return unless outputs.task_plan.valid?

    old_ecosystem = outputs.task_plan.ecosystem

    return if old_ecosystem == ecosystem

    outputs.task_plan.ecosystem = ecosystem

    return if old_ecosystem.nil? || !['reading', 'homework'].include?(outputs.task_plan.type)

    old_wrapped_ecosystem = Content::Ecosystem.new(strategy: old_ecosystem.wrap)
    new_wrapped_ecosystem = Content::Ecosystem.new(strategy: ecosystem.wrap)

    map = Content::Map.find_or_create_by(from_ecosystems: [old_wrapped_ecosystem],
                                         to_ecosystem: new_wrapped_ecosystem)

    fatal_error(code: :invalid_mapping) unless map.is_valid

    page_ids = outputs.task_plan.settings['page_ids']

    if page_ids.present?

      wrapped_pages_by_id = {}
      Content::Models::Page.where(id: page_ids).each do |page_model|
        wrapped_pages_by_id[page_model.id] = Content::Page.new(strategy: page_model.wrap)
      end

      page_map = map.map_pages_to_pages(pages: wrapped_pages_by_id.values)

      updated_page_ids = page_ids.map do |page_id|
        wrapped_page = wrapped_pages_by_id[page_id.to_i]
        page_map[wrapped_page].try!(:id).try!(:to_s)
      end.compact

    end

    outputs.task_plan.settings['page_ids'] = updated_page_ids

    return unless outputs.task_plan.type == 'homework'

    exercise_ids = outputs.task_plan.settings['exercise_ids']

    return unless exercise_ids.present?

    wrapped_exs_by_id = {}
    Content::Models::Exercise.where(id: exercise_ids).each do |ex_model|
      wrapped_exs_by_id[ex_model.id] = Content::Exercise.new(strategy: ex_model.wrap)
    end

    ex_to_page_map = map.map_exercises_to_pages(exercises: wrapped_exs_by_id.values)

    updated_exercise_ids = exercise_ids.map do |exercise_id|
      wrapped_ex = wrapped_exs_by_id[exercise_id.to_i]
      candidate_exercises = ex_to_page_map[wrapped_ex].homework_core_pool.exercises
      # TODO: Maybe migrate all exercises to have UUIDs and do this mapping by UUID
      candidate_exercises.find{ |ex| ex.number == wrapped_ex.number }.try!(:id).try!(:to_s)
    end.compact

    outputs.task_plan.settings['exercise_ids'] = updated_exercise_ids
  end

end
