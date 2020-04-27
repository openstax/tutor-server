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

    old_ecosystem = outputs.task_plan.set_ecosystem

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
      page_ids = outputs.task_plan.settings['page_ids']
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

    exercise_ids = outputs.task_plan.settings['exercise_ids'].map(&:to_i)

    return unless exercise_ids.present?

    # Update exercise ids to the new ecosystem by exercise number
    exercise_number_by_id = Content::Models::Exercise.where(
      id: exercise_ids
    ).pluck(:id, :number).to_h
    exercise_index_by_number = {}
    exercise_ids.each_with_index do |id, index|
      exercise_index_by_number[exercise_number_by_id[id]] = index
    end
    new_exercise_ids = []
    ecosystem.exercises.where(
      number: exercise_index_by_number.keys
    ).pluck(:id, :number).sort_by do |_, number|
      exercise_index_by_number[number]
    end.each { |id, _| new_exercise_ids << id.to_s }
    outputs.task_plan.settings['exercise_ids'] = new_exercise_ids
  end
end
