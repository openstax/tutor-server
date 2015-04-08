class RecoverTaskedExercise

  lev_routine

  uses_routine TaskExercise, as: :task_exercise
  uses_routine SearchLocalExercises, as: :search

  protected

  def exec(tasked_exercise:)
    fatal_error(code: :recovery_not_available) \
      unless tasked_exercise.can_be_recovered?

    recovery_exercise = get_recovery_exercise_for(
      tasked_exercise: tasked_exercise
    )

    fatal_error(code: :recovery_not_available) if recovery_exercise.nil?

    task_step = tasked_exercise.task_step

    recovery_step = create_task_step_after(task_step: task_step,
                                           exercise: recovery_exercise)
    transfer_errors_from(recovery_step, type: :verbatim)

    tasked_exercise.update_attribute(:can_be_recovered, false)

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
    step.tasked = run(:task_exercise, task_step: step, exercise: exercise)
                    .outputs.tasked_exercise
    task.task_steps << step
    step.save!
    step
  end

  # Finds an Exercise with all the required tags and at least one LO
  # Prefers unassigned Exercises
  def get_recovery_exercise_for(tasked_exercise:,
                                required_tag_names: ['practice-problem'])

    ex_relation = Content::Models::Exercise.preload(exercise_tags: :tag)

    # Randomize LO order
    los = tasked_exercise.wrapper.los.shuffle

    # Try to find unassigned exercises first
    taskees = tasked_exercise.task_step.task.taskings.collect{|t| t.role}
    los.each do |lo|
      exercise = run(:search,
        relation: ex_relation,
        not_assigned_to: taskees,
        tag: required_tag_names + [lo]
      ).outputs.items.shuffle.first

      return exercise unless exercise.nil?
    end

    # No unassigned exercises found, so return a previously assigned exercise
    los.each do |lo|
      exercise = run(:search,
        relation: ex_relation,
        tag: required_tag_names + [lo]
      ).outputs.items.shuffle.first

      return exercise unless exercise.nil?
    end

    # Nothing found
    nil
  end

end
