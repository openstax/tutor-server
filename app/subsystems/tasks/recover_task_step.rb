class Tasks::RecoverTaskStep

  lev_routine

  uses_routine TaskExercise, as: :task_exercise
  uses_routine SearchLocalExercises, as: :search

  protected

  def exec(task_step:)
    fatal_error(code: :recovery_not_available) unless task_step.can_be_recovered?

    # We can only handle course owners
    ecosystem = GetCourseEcosystem[course: task_step.task.task_plan.owner]

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

  # Get the student's reading assignments
  def self.get_taskee_ireading_history(taskee:)
    taskee.taskings
          .collect{ |tt| tt.task }
          .select{ |tt| tt.reading? }
          .sort_by{ |tt| tt.due_at }
          .reverse
  end

  # Get the page for each exercise in the student's assignments
  # From each page, get the pool of "try another" reading problems
  def self.get_exercise_pool(ecosystem:, exercises:)
    pages = exercises.collect{ |ex| ex.page }
    ecosystem.reading_try_another_pools(pages: pages).collect{ |pl| pl.exercises }.flatten
  end

  # Finds an Exercise with all the required tags and at least one LO
  # Prefers unassigned Exercises
  def get_recovery_exercise_for(ecosystem:, task_step:)
    ireading_history = get_taskee_ireading_history(taskee: taskee)

    flat_history = GetTasksExerciseHistory[ecosystem: ecosystem, tasks: ireading_history].flatten

    exercise_pool = get_exercise_pool(ecosystem: ecosystem, exercises: flat_history)

    candidate_exercises = (exercise_pool - flat_history).uniq

    los = task_step.tasked.los
    aplos = task_step.tasked.aplos

    # Find a random exercise that shares at least one LO with the tasked
    chosen_exercise = candidate_exercises.shuffle.find do |ex|
      (ex.los & los).any? || (ex.aplos & aplos).any?
    end

    if chosen_exercise.nil?
      # If no exercises found, reuse an old one
      chosen_exercise = exercise_pool.shuffle.find do |ex|
        ((ex.los & los).any? || (ex.aplos & aplos).any?) && ex.id != task_step.tasked.exercise.id
      end
    end

    chosen_exercise
  end

end
