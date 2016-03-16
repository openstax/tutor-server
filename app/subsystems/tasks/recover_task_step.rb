class Tasks::RecoverTaskStep

  lev_routine transaction: :serializable

  uses_routine TaskExercise, as: :task_exercise
  uses_routine GetEcosystemFromIds, as: :get_ecosystem
  uses_routine GetHistory, as: :get_history
  uses_routine FilterExcludedExercises, as: :filter
  uses_routine ChooseExercises, as: :choose

  protected

  def exec(task_step:)
    fatal_error(code: :recovery_not_available) unless task_step.lock!.can_be_recovered?

    # Get the ecosystem from the content_exercise_id
    exercise_id = task_step.tasked.content_exercise_id
    ecosystem = run(:get_ecosystem, exercise_ids: exercise_id).outputs.ecosystem

    recovery_exercise = get_recovery_exercise_for(ecosystem: ecosystem, task_step: task_step)

    fatal_error(code: :recovery_not_found) if recovery_exercise.nil?

    recovery_step = create_task_step_after(task_step: task_step, exercise: recovery_exercise)
    transfer_errors_from(recovery_step, type: :verbatim)

    task_step.tasked.update_attribute(:can_be_recovered, false)

    outputs[:recovery_exercise] = recovery_exercise
    outputs[:recovery_step] = recovery_step
    outputs[:task] = recovery_step.task
  end

  private

  # Inserts a new TaskStep for the given Exercise after the given TaskStep
  def create_task_step_after(task_step:, exercise:)
    task = task_step.task
    step = Tasks::Models::TaskStep.new(
      task: task, number: task_step.number + 1
    )
    step.tasked = run(:task_exercise, task_step: step, exercise: exercise).outputs.tasked_exercise
    step.group_type = :recovery_group
    task.task_steps << step
    step.save!
    step
  end

  # Get the page for each exercise in the student's assignments
  # From each page, get the pool of "try another" reading problems
  def get_pool_exercises(ecosystem:, exercise:)
    page = exercise.page
    ecosystem.reading_try_another_pools(pages: page).flat_map(&:exercises)
  end

  # Finds an Exercise with all the required tags and at least one LO
  # Prefers unassigned Exercises
  def get_recovery_exercise_for(ecosystem:, task_step:)
    # Assume only 1 taskee for now
    role = task_step.task.entity_task.taskings.map(&:role).first

    task_exercise_numbers = task_step.task.tasked_exercises.map{ |te| te.exercise.number }

    recovered_exercise_id = task_step.tasked.content_exercise_id
    recovered_exercise = ecosystem.exercises_by_ids(recovered_exercise_id).first
    pool_exercises = get_pool_exercises(ecosystem: ecosystem, exercise: recovered_exercise)

    course = role.student.try(:course)
    filtered_exercises = run(:filter, exercises: pool_exercises, course: course,
                                      additional_excluded_numbers: task_exercise_numbers)
                           .outputs.exercises

    los = Set.new(recovered_exercise.los)
    aplos = Set.new(recovered_exercise.aplos)

    # Allow only exercises that share at least one LO or APLO with the tasked
    candidate_exercises = filtered_exercises.select do |ex|
      ex.los.any?{ |tt| los.include?(tt) } || ex.aplos.any?{ |tt| aplos.include?(tt) }
    end

    history = run(:get_history, role: role, type: :all).outputs
    chosen_exercise = run(:choose, exercises: candidate_exercises,
                                   count: 1, history: history).outputs.exercises.first
    chosen_exercise
  end

end
