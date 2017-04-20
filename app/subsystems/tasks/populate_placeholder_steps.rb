class Tasks::PopulatePlaceholderSteps

  lev_routine express_output: :task

  uses_routine TaskExercise, as: :task_exercise

  protected

  def exec(task:)
    outputs.task = task.lock!

    # Skip if no placeholders
    placeholder_task_steps = task.task_steps(preload_tasked: true).select(&:placeholder?)
    return if placeholder_task_steps.empty?

    # If the task is a reading, we give Biglearn control of the number of slots
    # Placeholders are merely used to determine the size of the bar the student sees
    biglearn_controls_slots = task.reading?

    # Populate PEs
    populate_placeholder_steps task: task,
                               group_type: :personalized_group,
                               biglearn_api_method: :fetch_assignment_pes,
                               biglearn_controls_slots: biglearn_controls_slots

    taskings = task.taskings
    role = taskings.first.try!(:role)

    # To prevent "skim-filling", skip populating spaced practice if not all core problems
    # have been completed AND there is an open assignment with an earlier due date
    unless task.core_task_steps_completed?
      same_role_taskings = role.taskings
      task_type = Tasks::Models::Task.task_types[task.task_type]
      due_at = task.due_at
      current_time = Time.current
      return if same_role_taskings.joins(:task)
                                  .where(task: { task_type: task_type })
                                  .preload(task: :time_zone)
                                  .map(&:task)
                                  .any? do |task|
        task.due_at < due_at &&
        task.past_open?(current_time: current_time) &&
        !task.past_due?(current_time: current_time)
      end
    end

    # Populate SPEs
    populate_placeholder_steps task: task,
                               group_type: :spaced_practice_group,
                               biglearn_api_method: :fetch_assignment_spes,
                               biglearn_controls_slots: biglearn_controls_slots

    # Ensure the correct steps are returned
    task.task_steps.reset

    # Ensure the lock works
    task.touch

    # Can't send the info to Biglearn if there's no course
    course = role.try!(:student).try!(:course)
    return if course.nil?

    # Send the updated assignment to Biglearn
    OpenStax::Biglearn::Api.create_update_assignments(course: course, task: task)
  end

  def populate_placeholder_steps(task:, group_type:, biglearn_api_method:, biglearn_controls_slots:)
    if biglearn_controls_slots
      # Biglearn controls how many PEs/SPEs (reading tasks)
      chosen_exercises = OpenStax::Biglearn::Api.public_send biglearn_api_method, task: task
      chosen_exercise_models = chosen_exercises.map(&:to_model)
      # Group steps and exercises by content_page_id; Spaced Practice uses nil content_page_ids
      task_steps_by_page_id = task.task_steps.group_by(&:content_page_id)
      grouped_chosen_exercises = group_type == :personalized_group ?
                                   chosen_exercise_models.group_by(&:content_page_id) :
                                   { nil => chosen_exercise_models }
      # Keep track of the number of steps we added to the task
      num_added_steps = 0

      # Populate each page at a time to ensure we get the correct number of steps for each
      task_steps_by_page_id.each do |page_id, page_task_steps|
        exercises = grouped_chosen_exercises[page_id] || []
        placeholder_steps = page_task_steps.select do |task_step|
          task_step.placeholder? && task_step.group_type == group_type.to_s
        end

        last_step = page_task_steps.last
        max_page_step_number = last_step.try!(:number) || 0
        related_content = last_step.try!(:related_content)
        labels = last_step.try!(:labels)

        # Iterate through all the exercises and steps
        # Add/remove steps as needed
        num_iterations = [exercises.size, placeholder_steps.size].max
        num_iterations.times do |index|
          exercise = exercises[index]
          task_step = placeholder_steps[index]

          if exercise.nil? || exercise.questions_hash.blank?
            # Extra step: Remove it
            # We don't compact the task steps (gaps are ok) so we don't decrement num_added_steps
            task_step.try!(:really_destroy!)
          else
            if task_step.nil?
              # Need a new step for this exercise
              next_step_number = max_page_step_number + num_added_steps + 1
              task_step = Tasks::Models::TaskStep.new(
                task: task,
                number: next_step_number,
                group_type: group_type,
                content_page_id: exercise.content_page_id,
                related_content: related_content,
                labels: labels
              )

              num_added_steps += exercise.number_of_parts
            else
              # Reuse a placeholder step
              task_step.tasked.really_destroy!
              # Adjust the step number to be correct based on how many steps we've added
              # since we are avoiding reloading
              task_step.number += num_added_steps
              task_step.changes_applied

              num_added_steps += exercise.number_of_parts - 1
            end

            # Assign the exercise (handles multipart questions, etc)
            run(:task_exercise, task_step: task_step, exercise: exercise)
          end
        end
      end
    else
      # Tutor controls how many PEs/SPEs (homework tasks)
      placeholder_steps = task.task_steps.select do |task_step|
        task_step.placeholder? && task_step.group_type == group_type.to_s
      end
      return if placeholder_steps.empty?

      # max_num_exercises ensures we don't get more exercises than the number of placeholders
      chosen_exercises = OpenStax::Biglearn::Api.public_send(
        biglearn_api_method, task: task, max_num_exercises: placeholder_steps.size
      )

      # This code is much simpler because it doesn't have to account for steps being added
      placeholder_steps.each_with_index do |task_step, index|
        exercise = chosen_exercises[index]

        # If no exercise available, hard-delete the Placeholder TaskStep and the TaskedPlaceholder
        next task_step.really_destroy! if exercise.nil?

        # Otherwise, hard-delete just the TaskedPlaceholder
        task_step.tasked.really_destroy!

        # Assign the exercise (handles multipart questions, etc)
        run(:task_exercise, task_step: task_step, exercise: exercise)
      end
    end
  end

end
