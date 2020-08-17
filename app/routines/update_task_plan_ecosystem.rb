class UpdateTaskPlanEcosystem
  # Readings, homeworks and extras are the only TaskPlan types that
  # require changes to their settings to work with newer ecosystems
  TPS_THAT_NEED_UPDATES = ['reading', 'homework', 'extra']

  lev_routine express_output: :task_plan

  protected

  def exec(task_plan:, ecosystem:, save: true)
    update_task_plan(task_plan: task_plan, ecosystem: ecosystem)

    outputs.task_plan.save if save
  end

  def update_task_plan(task_plan:, ecosystem:)
    # No need to lock the plan because it should not be saved yet
    outputs.task_plan = task_plan

    old_ecosystem = outputs.task_plan.set_and_return_ecosystem

    return if old_ecosystem == ecosystem

    outputs.task_plan.ecosystem = ecosystem

    return if old_ecosystem.nil? || !TPS_THAT_NEED_UPDATES.include?(outputs.task_plan.type)

    map = Content::Map.find_or_create_by(
      from_ecosystems: [ old_ecosystem ], to_ecosystem: ecosystem
    )

    fatal_error(code: :invalid_mapping) unless map.is_valid

    if outputs.task_plan.type == 'extra'
      snap_lab_ids = outputs.task_plan.settings['snap_lab_ids']
      page_ids = snap_lab_ids.map{ |page_id_snap_lab_id| page_id_snap_lab_id.split(':').first }
    else
      page_ids = outputs.task_plan.core_page_ids
    end

    unless page_ids.nil?
      page_id_map = map.map_page_ids(page_ids: page_ids)

      if outputs.task_plan.type == 'extra'
        outputs.task_plan.settings['snap_lab_ids'] = snap_lab_ids.each_with_index
                                                                 .map do |page_id_snap_lab_id, idx|
          page_id, snap_lab_id = page_id_snap_lab_id.split(':', 2)
          updated_page_id = page_id_map[page_id]&.to_s
          next if updated_page_id.nil?

          "#{updated_page_id}:#{snap_lab_id}"
        end.compact
      else
        outputs.task_plan.settings['page_ids'] = page_ids.map do |page_id|
          page_id_map[page_id]&.to_s
        end.compact
      end
    end

    return unless outputs.task_plan.type == 'homework'

    exercises = outputs.task_plan.settings['exercises']

    return unless exercises.present?

    # Update exercises to the new ecosystem by exercise number
    exercise_number_by_id = Content::Models::Exercise.where(
      id: exercises.map { |ex| ex['id'] }
    ).pluck(:id, :number).to_h
    exercise_numbers = exercises.map { |exercise| exercise_number_by_id[exercise['id'].to_i] }
    new_exercise_id_by_number = ecosystem.exercises.where(
      number: exercise_numbers
    ).pluck(:number, :id).to_h
    outputs.task_plan.settings['exercises'] = exercises.each_with_index.map do |hash, index|
      id = new_exercise_id_by_number[exercise_numbers[index]]
      next if id.nil?

      { 'id' => id.to_s, 'points' => hash['points'] }
    end.compact
  end
end
