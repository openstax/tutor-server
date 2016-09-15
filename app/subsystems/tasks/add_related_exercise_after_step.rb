class Tasks::AddRelatedExerciseAfterStep

  lev_routine

  uses_routine TaskExercise, as: :task_exercise, translations: { outputs: { type: :verbatim } }
  uses_routine GetEcosystemFromIds, as: :get_ecosystem
  uses_routine GetHistory, as: :get_history
  uses_routine FilterExcludedExercises, as: :filter
  uses_routine ChooseExercises, as: :choose

  protected

  def exec(task_step:)
    # These locks are here to prevent double clicks on the Try Another/Try One buttons
    task_step.task.lock!
    fatal_error(code: :related_exercise_not_available) unless task_step.lock!.can_be_recovered?

    related_exercise = get_related_exercise_for(task_step: task_step)

    fatal_error(code: :related_exercise_not_found) if related_exercise.nil?

    related_exercise_step = create_exercise_step_after(task_step: task_step,
                                                       exercise: related_exercise)

    # This update combined with the lock above will cause other transactions to retry
    task_step.update_attribute(:related_exercise_ids, [])

    outputs[:related_exercise] = related_exercise_step
    outputs[:related_exercise_step] = related_exercise_step
    outputs[:task] = related_exercise_step.task
  end

  # Inserts a new TaskStep with a TaskedExercise after the given TaskStep using the given Exercise
  def create_exercise_step_after(task_step:, exercise:)
    run(:task_exercise, exercise: exercise, task: task_step.task) do |step|
      step.number = task_step.number + 1
      step.group_type = :recovery_group
    end

    outputs[:task_steps].first.tap(&:save!)
  end

  # Finds an Exercise with all the required tags and at least one LO
  # Prefers unassigned Exercises
  def get_related_exercise_for(task_step:)
    # Transform the exercise ids into Ecosystem exercises
    related_exercise_ids = task_step.related_exercise_ids
    ecosystem = run(:get_ecosystem, exercise_ids: related_exercise_ids).outputs.ecosystem
    related_exercises = ecosystem.exercises_by_ids(related_exercise_ids)

    # Assume only 1 taskee for now
    role = task_step.task.taskings.map(&:role).first
    course = role.student.try(:course)

    task_exercise_numbers = task_step.task.tasked_exercises.map{ |te| te.exercise.number }

    candidate_exercises = run(:filter, exercises: related_exercises, course: course,
                                       additional_excluded_numbers: task_exercise_numbers)
                            .outputs.exercises

    history = run(:get_history, roles: role, type: :all).outputs.history[role]

    run(:choose, exercises: candidate_exercises, count: 1, history: history).outputs.exercises.first
  end

end
