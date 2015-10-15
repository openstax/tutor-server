class Tasks::RecoverTaskStep

  lev_routine

  uses_routine TaskExercise, as: :task_exercise
  uses_routine GetEcosystemFromIds, as: :get_ecosystem
  uses_routine GetHistory, as: :get_history

  protected

  def exec(task_step:)
    fatal_error(code: :recovery_not_available) unless task_step.can_be_recovered?

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
    task.task_steps << step
    step.save!
    step
  end

  # Get the page for each exercise in the student's assignments
  # From each page, get the pool of "try another" reading problems
  def get_exercise_pool(ecosystem:, exercise:)
    page = exercise.page
    ecosystem.reading_try_another_pools(pages: page).collect{ |pl| pl.exercises }.flatten
  end

  # Finds an Exercise with all the required tags and at least one LO
  # Prefers unassigned Exercises
  def get_recovery_exercise_for(ecosystem:, task_step:)
    # Assume only 1 taskee for now
    role = task_step.task.entity_task.taskings.collect{ |tt| tt.role }.first

    all_worked_exercises = run(:get_history, role: role, type: :all).outputs.exercises.flatten.uniq

    recovered_exercise_id = task_step.tasked.content_exercise_id
    recovered_exercise = ecosystem.exercises_by_ids(recovered_exercise_id).first
    exercise_pool = get_exercise_pool(ecosystem: ecosystem, exercise: recovered_exercise)

    candidate_exercises = (exercise_pool - all_worked_exercises).uniq

    los = Set.new(recovered_exercise.los)
    aplos = Set.new(recovered_exercise.aplos)

    # Find a random exercise that shares at least one LO with the tasked
    chosen_exercise = candidate_exercises.shuffle.find do |ex|
      ex.los.any?{ |tt| los.include?(tt) } || ex.aplos.any?{ |tt| aplos.include?(tt) }
    end

    if chosen_exercise.nil?
      # If no exercises found, reuse an old one
      chosen_exercise = exercise_pool.shuffle.find do |ex|
        ex != recovered_exercise && \
        (ex.los.any?{ |tt| los.include?(tt) } || ex.aplos.any?{ |tt| aplos.include?(tt) })
      end
    end

    chosen_exercise
  end

end
