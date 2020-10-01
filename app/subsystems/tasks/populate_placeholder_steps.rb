class Tasks::PopulatePlaceholderSteps
  lev_routine transaction: :read_committed, express_output: :task

  uses_routine GetTaskCorePageIds, as: :get_task_core_page_ids
  uses_routine Tasks::FetchAssignmentPes, as: :fetch_assignment_pes
  uses_routine Tasks::FetchAssignmentSpes, as: :fetch_assignment_spes
  uses_routine TaskExercise, as: :task_exercise

  protected

  def exec(task:, force: false, lock_task: true, populate_spes: true, save: true)
    outputs.task = task

    return if already_populated?(task, populate_spes)

    if lock_task
      task.lock!
      # check again after locking to make sure it wasn't updated
      return if already_populated?(task, populate_spes)
    end

    # Lock the task_steps to ensure they don't get updated without us noticing
    task.task_steps.lock('FOR NO KEY UPDATE').reload

    pes_populated = false
    unless task.pes_are_assigned
      # Populate PEs
      populate_placeholder_steps(
        task: task,
        group_type: :personalized_group,
        exercise_type: :pe,
        save: save
      )
      pes_populated = task.pes_are_assigned
    end

    taskings = task.taskings
    role = taskings.first&.role

    # To prevent "skim-filling", skip populating
    # spaced practice if not all core problems have been completed
    spes_populated = false
    if populate_spes && !task.spes_are_assigned && (force || task.core_task_steps_completed?)
      # Populate SPEs
      populate_placeholder_steps(
        task: task,
        group_type: :spaced_practice_group,
        exercise_type: :spe,
        save: save
      )
      spes_populated = task.spes_are_assigned
    end

    return unless pes_populated || spes_populated

    # Update step counts
    task.update_caches_now

    # Save modified fields
    task.save validate: false
  end

  def already_populated?(task, populate_spes)
    task.pes_are_assigned && (!populate_spes || task.spes_are_assigned)
  end

  def populate_placeholder_steps(task:, group_type:, exercise_type:, save:)
    # Get the task core_page_ids (only necessary for spaced_practice_group)
    core_page_ids = run(:get_task_core_page_ids, tasks: task)
      .outputs.task_id_to_core_page_ids_map[task.id] if group_type == :spaced_practice_group
    exercise_routine = "fetch_assignment_#{exercise_type}s".to_sym
    boolean_attribute = "#{exercise_type}s_are_assigned"

    task_steps_to_upsert = []
    tasked_exercises_to_import = []
    task_step_ids_to_delete = []
    tasked_placeholder_ids_to_delete = []
    calculation_uuid = nil

    placeholder_steps = task.task_steps.filter do |task_step|
      task_step.placeholder? && task_step.group_type == group_type.to_s
    end
    if placeholder_steps.empty?
      task.update_attribute boolean_attribute, true
      return
    end

    ActiveRecord::Associations::Preloader.new.preload(placeholder_steps, :tasked)

    outs = run(exercise_routine, task: task).outputs
    chosen_exercises = outs.exercises

    # Group placeholder steps and exercises by content_page_id
    # Spaced Practice uses nil content_page_ids
    placeholder_steps_by_page_id = placeholder_steps.group_by(&:content_page_id)
    exercises_by_page_id = group_type == :personalized_group ?
                             chosen_exercises.group_by(&:content_page_id) :
                             { nil => chosen_exercises }
    placeholder_steps_by_page_id.each do |page_id, page_placeholder_steps|
      # Always delete TaskedPlaceholders
      tasked_placeholder_ids_to_delete.concat page_placeholder_steps.map(&:tasked_id)

      exercises = exercises_by_page_id[page_id] || []

      exercises.each do |exercise|
        break if page_placeholder_steps.empty?

        # Assign the exercise (handles multipart questions, etc)
        out = run(
          :task_exercise,
          task_steps: page_placeholder_steps,
          exercise: exercise,
          allow_save: false
        ).outputs
        task_steps = out.task_steps

        task_steps.each do |task_step|
          # Detect PEs being used as SPEs and set the step type to :personalized_group
          # So they are displayed as personalized exercises
          task_step.group_type = :personalized_group \
            if group_type == :spaced_practice_group &&
               core_page_ids.include?(exercise.content_page_id)
        end

        task_steps_to_upsert.concat task_steps
        tasked_exercises_to_import.concat out.tasked_exercises
        page_placeholder_steps -= task_steps
      end

      # If not enough exercises available, hard-delete any remaining Placeholder TaskSteps
      task_step_ids_to_delete.concat page_placeholder_steps.map(&:id)
    end

    Tasks::Models::TaskedPlaceholder.where(id: tasked_placeholder_ids_to_delete).delete_all \
      unless tasked_placeholder_ids_to_delete.empty?

    Tasks::Models::TaskStep.where(id: task_step_ids_to_delete).delete_all \
      unless task_step_ids_to_delete.empty?

    Tasks::Models::TaskedExercise.import(tasked_exercises_to_import, validate: false) \
      unless tasked_exercises_to_import.empty?

    unless task_steps_to_upsert.empty?
      existing_task_steps = task.task_steps.reject { |ts| task_step_ids_to_delete.include? ts.id }
      non_updated_task_steps = existing_task_steps - task_steps_to_upsert
      task_steps = non_updated_task_steps + task_steps_to_upsert
      next_step_number = (task_steps.map(&:number).compact.max || 0) + 1
      task_steps_to_upsert.each do |task_step|
        # Reassign the tasked exercises so the tasked_ids are properly set
        task_step.tasked = task_step.tasked

        # Take care of duplicate task_step numbers
        if task_step.number.nil?
          task_step.number = next_step_number
          next_step_number += 1
        elsif task_steps.any? { |ts| ts.number == task_step.number && ts.id != task_step.id }
          conflicting_non_updated_task_steps = non_updated_task_steps.select do |ts|
            ts.number >= task_step.number && ts.id != task_step.id
          end
          non_updated_task_steps -= conflicting_non_updated_task_steps
          # FIXME: This is modifying the task_steps_to_upsert array during iteration
          task_steps_to_upsert.concat conflicting_non_updated_task_steps
          task_steps_to_upsert.select do |ts|
            ts.number >= task_step.number && ts.id != task_step.id
          end.each { |ts| ts.number = ts.number + 1 }
          next_step_number += 1
        end
      end

      Tasks::Models::TaskStep.import(
          task_steps_to_upsert.sort_by(&:number).reverse, validate: false,
                                                          on_duplicate_key_update: {
            conflict_target: [ :id ], columns: [
              :tasked_type,
              :tasked_id,
              :number,
              :first_completed_at,
              :last_completed_at,
              :group_type,
              :is_core,
              :content_page_id
            ]
          }
      )
    end

    task.task_steps.reset

    task.spy["#{exercise_type}s"] = outs.slice(
      'eligible_page_ids',
      'initially_eligible_exercise_uids',
      'admin_excluded_uids',
      'course_excluded_uids',
      'role_excluded_uids'
    )

    task.send "#{boolean_attribute}=", true

    task.save(validate: false) if save
  end
end
