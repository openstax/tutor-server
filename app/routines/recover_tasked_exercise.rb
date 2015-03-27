# Move to whatever subsystem handles the user doing homework (iReadings)

class RecoverTaskedExercise

  lev_routine

  protected

  def exec(tasked_exercise:)
    fatal_error(code: :missing_recovery_exercise) \
      unless tasked_exercise.has_recovery?

    recovery_exercise = tasked_exercise.recovery_tasked_exercise
    outputs[:recovery_exercise] = recovery_exercise
    task_step = tasked_exercise.task_step
    task = task_step.task
    outputs[:task] = task

    recovery_step = TaskStep.new(task: task, number: task_step.number + 1)
    outputs[:recovery_step] = recovery_step
    recovery_step.tasked = recovery_exercise
    tasked_exercise.recovery_tasked_exercise = nil
    task.task_steps << recovery_step
    recovery_step.save!
    transfer_errors_from(recovery_step, type: :verbatim)

    tasked_exercise.recovery_tasked_exercise = nil
    tasked_exercise.save!(validate: false)
    transfer_errors_from(tasked_exercise, type: :verbatim)
  end
end
