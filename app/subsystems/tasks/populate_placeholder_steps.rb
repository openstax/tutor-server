class Tasks::PopulatePlaceholderSteps

  lev_routine express_output: :task

  uses_routine TaskExercise, as: :task_exercise

  protected

  def exec(task:)
    outputs.task = task.lock!

    # Skip if no placeholders
    placeholder_task_steps = task.task_steps(preload_tasked: true).select(&:placeholder?)
    return if placeholder_task_steps.empty?

    # Populate PEs
    pe_placeholders = placeholder_task_steps.select(&:personalized_group?)
    populate_placeholder_steps task: task,
                               placeholder_steps: pe_placeholders,
                               biglearn_api_method: :fetch_assignment_pes

    taskings = task.taskings
    role = taskings.first.try!(:role)

    # To prevent "skim-filling", skip populating spaced practice if not all core problems
    # have been completed AND there is an open assignment with an earlier due date
    unless task.core_task_steps_completed?
      same_role_taskings = role.taskings
      due_at = task.due_at
      current_time = Time.current
      return if same_role_taskings.preload(task: :time_zone).map(&:task).any? do |task|
        task.due_at < due_at &&
        task.past_open?(current_time: current_time) &&
        !task.past_due?(current_time: current_time)
      end
    end

    # Populate SPEs
    spe_placeholders = placeholder_task_steps.select(&:spaced_practice_group?)
    populate_placeholder_steps task: task,
                               placeholder_steps: spe_placeholders,
                               biglearn_api_method: :fetch_assignment_spes

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

  def populate_placeholder_steps(task:, placeholder_steps:, biglearn_api_method:)
    return if placeholder_steps.empty?

    chosen_exercises = OpenStax::Biglearn::Api.public_send(
      biglearn_api_method, task: task, max_num_exercises: placeholder_steps.size
    )

    placeholder_steps.each_with_index do |task_step, index|
      exercise = chosen_exercises[index]

      # If no exercise available, hard-delete the Placeholder TaskStep and the TaskedPlaceholder
      next task_step.really_destroy! if exercise.nil?

      # Otherwise, hard-delete just the TaskedPlaceholder
      task_step.tasked.really_destroy!

      run(:task_exercise, task_step: task_step, exercise: exercise)
    end
  end

end
