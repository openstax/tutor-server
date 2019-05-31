class Tasks::PopulatePlaceholderSteps

  lev_routine transaction: :read_committed, express_output: :task

  uses_routine GetTaskCorePageIds, as: :get_task_core_page_ids
  uses_routine TaskExercise, as: :task_exercise
  uses_routine TranslateBiglearnSpyInfo, as: :translate_biglearn_spy_info

  protected

  def exec(task:, force: false, lock_task: true, background: false,
           skip_unready: false, populate_spes: true)
    outputs.task = task
    outputs.accepted = true

    return if already_populated?(task, populate_spes)

    if lock_task
      task.lock!
      # check again after locking to make sure it wasn't updated
      return if already_populated?(task, populate_spes)
    end

    # Lock the task_steps to ensure they don't get updated without us noticing
    task.task_steps.lock('FOR NO KEY UPDATE').reload

    # If the task is a practice widget, we give Biglearn control of the number of PE slots
    biglearn_controls_pe_slots = task.practice?
    biglearn_controls_spe_slots = false

    unless task.pes_are_assigned
      # Populate PEs
      task, accepted = populate_placeholder_steps(
        task: task,
        group_type: :personalized_group,
        boolean_attribute: :pes_are_assigned,
        biglearn_api_method: :fetch_assignment_pes,
        biglearn_controls_slots: biglearn_controls_pe_slots,
        background: background,
        skip_unready: skip_unready
      )
      outputs.accepted = false unless accepted
    end

    taskings = task.taskings
    role = taskings.first.try!(:role)

    if populate_spes && !task.spes_are_assigned
      # To prevent "skim-filling", skip populating spaced practice if not all core problems
      # have been completed AND there is an open assignment with an earlier due date
      same_role_taskings = role.try!(:taskings) || Tasks::Models::Tasking.none
      task_type = Tasks::Models::Task.task_types[task.task_type]
      due_at = task.due_at
      current_time = Time.current
      if force ||
         task.core_task_steps_completed? ||
         due_at.nil? ||
         same_role_taskings.joins(:task)
                           .where(task: { task_type: task_type })
                           .preload(task: :time_zone)
                           .map(&:task)
                           .none? do |task|
           task.due_at.present? &&
           task.due_at < due_at &&
           task.past_open?(current_time: current_time) &&
           !task.past_due?(current_time: current_time)
         end

        # Populate SPEs
        task, accepted = populate_placeholder_steps(
          task: task,
          group_type: :spaced_practice_group,
          boolean_attribute: :spes_are_assigned,
          biglearn_api_method: :fetch_assignment_spes,
          biglearn_controls_slots: biglearn_controls_spe_slots,
          background: background,
          skip_unready: skip_unready
        )
        outputs.accepted = false unless accepted
      end
    end

    # Save pes_are_assigned/spes_are_assigned and step counts
    task.update_step_counts.save validate: false

    task.update_caches_later update_step_counts: false

    # Can't send the info to Biglearn if there's no course
    return if role.nil?

    course = role.course
    return if course.nil?

    # Send the updated assignment to Biglearn
    OpenStax::Biglearn::Api.create_update_assignments(course: course, task: task)
  end

  def already_populated?(task, populate_spes)
    task.pes_are_assigned && (!populate_spes || task.spes_are_assigned)
  end

  def populate_placeholder_steps(task:, group_type:, boolean_attribute:, biglearn_api_method:,
                                 biglearn_controls_slots:, background:, skip_unready:)
    # Get the task core_page_ids (only necessary for spaced_practice_group)
    core_page_ids = run(:get_task_core_page_ids, tasks: task)
      .outputs.task_id_to_core_page_ids_map[task.id] if group_type == :spaced_practice_group
    max_attempts = skip_unready ? 1 : background ? 600 : 30
    sleep_interval = skip_unready ? 0 : 1.second

    task_steps_to_upsert = []
    tasked_exercises_to_import = []
    task_step_ids_to_delete = []
    tasked_placeholder_ids_to_delete = []

    if biglearn_controls_slots
      # Biglearn controls how many PEs/SPEs
      result = OpenStax::Biglearn::Api.public_send biglearn_api_method,
                                                   task: task,
                                                   inline_max_attempts: max_attempts,
                                                   inline_sleep_interval: sleep_interval,
                                                   enable_warnings: !skip_unready
      # Bail if we are supposed to retry this in the background
      return [ task, false ] if !result[:accepted] && skip_unready

      chosen_exercises = result[:exercises].map(&:to_model)
      spy_info = run(:translate_biglearn_spy_info, spy_info: result[:spy_info]).outputs.spy_info
      exercise_spy_info = spy_info.fetch('exercises', {})

      # Group steps and exercises by content_page_id; Spaced Practice uses nil content_page_ids
      task_steps_by_page_id = task.task_steps.group_by(&:content_page_id)
      exercises_by_page_id = group_type == :personalized_group ?
                               chosen_exercises.group_by(&:content_page_id) :
                               { nil => chosen_exercises }

      # Keep track of the number of steps we added to the task
      num_added_steps = 0

      # Populate each page one at a time to ensure we get the correct number of steps for each
      task_steps_by_page_id.each do |page_id, page_task_steps|
        exercises = exercises_by_page_id[page_id] || []
        placeholder_steps = page_task_steps.select do |task_step|
          task_step.placeholder? && task_step.group_type == group_type.to_s
        end
        ActiveRecord::Associations::Preloader.new.preload(placeholder_steps, :tasked)

        last_step = page_task_steps.last
        max_page_step_number = last_step.try!(:number) || 0
        labels = last_step.try!(:labels)

        # Iterate through all the exercises and steps
        # Add/remove steps as needed
        [exercises.size, placeholder_steps.size].max.times do |index|
          exercise = exercises[index]
          task_step = placeholder_steps[index]

          if exercise.nil? || exercise.questions_hash.blank?
            # Extra step: Remove it
            # We don't compact the task steps (gaps are ok) so we don't decrement num_added_steps
            task_step_ids_to_delete << task_step.id
            tasked_placeholder_ids_to_delete << task_step.tasked_id
          else
            if task_step.nil?
              # Need a new step for this exercise
              next_step_number = max_page_step_number + num_added_steps + 1
              task_step = Tasks::Models::TaskStep.new(
                task: task,
                number: next_step_number,
                group_type: group_type,
                content_page_id: exercise.content_page_id,
                labels: labels
              )

              num_added_steps += exercise.number_of_parts
            else
              # Reuse a placeholder step
              tasked_placeholder_ids_to_delete << task_step.tasked_id

              # Adjust the step number to be correct based on how many steps we've added
              # since we are avoiding reloading
              task_step.number += num_added_steps
              task_step.changes_applied

              num_added_steps += exercise.number_of_parts - 1
            end

            # Detect PEs being used as SPEs and set the step type to :personalized_group
            # So they are displayed as personalized exercises
            task_step.group_type = :personalized_group \
              if group_type == :spaced_practice_group &&
                 core_page_ids.include?(exercise.content_page_id)

            task_step.spy = exercise_spy_info.fetch(exercise.uuid, {})

            # Assign the exercise (handles multipart questions, etc)
            out = run(
              :task_exercise, task_step: task_step, exercise: exercise, allow_save: false
            ).outputs
            task_steps_to_upsert.concat out.task_steps
            tasked_exercises_to_import.concat out.tasked_exercises
          end
        end
      end
    else
      # Tutor controls how many PEs/SPEs
      placeholder_steps = task.task_steps.to_a.select do |task_step|
        task_step.placeholder? && task_step.group_type == group_type.to_s
      end
      if placeholder_steps.empty?
        task.update_attribute boolean_attribute, true
        return [ task, true ]
      end

      ActiveRecord::Associations::Preloader.new.preload(placeholder_steps, :tasked)

      # max_num_exercises ensures we don't get more exercises than the number of placeholders
      result = OpenStax::Biglearn::Api.public_send(
        biglearn_api_method,
        task: task,
        max_num_exercises: placeholder_steps.size,
        inline_max_attempts: max_attempts,
        inline_sleep_interval: sleep_interval,
        enable_warnings: !skip_unready
      )
      # Bail if we are supposed to retry this in the background
      return [ task, false ] if !result[:accepted] && skip_unready

      chosen_exercises = result[:exercises].map(&:to_model)
      spy_info = run(:translate_biglearn_spy_info, spy_info: result[:spy_info]).outputs.spy_info
      exercise_spy_info = spy_info.fetch('exercises', {})

      # This code is much simpler because it doesn't have to account for steps being added
      # Group placeholder steps and exercises by content_page_id
      # Spaced Practice uses nil content_page_ids
      placeholder_steps_by_page_id = placeholder_steps.group_by(&:content_page_id)
      exercises_by_page_id = group_type == :personalized_group ?
                               chosen_exercises.group_by(&:content_page_id) :
                               { nil => chosen_exercises }
      placeholder_steps_by_page_id.each do |page_id, page_placeholder_steps|
        exercises = exercises_by_page_id[page_id] || []

        page_placeholder_steps.each_with_index do |task_step, index|
          exercise = exercises[index]

          # Always delete the TaskedPlaceholder
          tasked_placeholder_ids_to_delete << task_step.tasked_id

          # If no exercise available, also hard-delete the Placeholder TaskStep
          next task_step_ids_to_delete << task_step.id if exercise.nil?

          # Detect PEs being used as SPEs and set the step type to :personalized_group
          # So they are displayed as personalized exercises
          task_step.group_type = :personalized_group \
            if group_type == :spaced_practice_group &&
               core_page_ids.include?(exercise.content_page_id)

          task_step.spy = exercise_spy_info.fetch(exercise.uuid, {})

          # Assign the exercise (handles multipart questions, etc)
          out = run(
            :task_exercise, task_step: task_step, exercise: exercise, allow_save: false
          ).outputs
          task_steps_to_upsert.concat out.task_steps
          tasked_exercises_to_import.concat out.tasked_exercises
        end
      end
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
          task_steps_to_upsert.sort_by(&:number).reverse, validate: false, on_duplicate_key_update: {
            conflict_target: [ :id ], columns: [
              :tasked_type,
              :tasked_id,
              :number,
              :first_completed_at,
              :last_completed_at,
              :group_type,
              :spy,
              :content_page_id
            ]
          }
      )
    end

    task.task_steps.reset

    task.spy = task.spy.merge(spy_info.except('exercises'))
    task.send "#{boolean_attribute}=", true

    [ task, !!result[:accepted] ]
  end

end
