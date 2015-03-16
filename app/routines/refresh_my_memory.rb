# Move to task (do iReading) subsystem

class RefreshMyMemory

  lev_routine

  uses_routine TryAnother, as: :try_another,
                           translations: { outputs: { type: :verbatim } }

  protected

  def exec(tasked_exercise:)
    refresh_tasked = tasked_exercise.refresh_tasked
    fatal_error(:missing_refresh_step) if refresh_tasked.nil?

    task_step = tasked_exercise.task_step
    run(:try_another, tasked_exercise: tasked_exercise)
    task = outputs[:task]
    recovery_step = outputs[:recovery_step]
    recovery_step.save!

    refresh_step = TaskStep.new(task: task, number: recovery_step.number)
    outputs[:refresh_step] = refresh_step
    refresh_step.tasked = refresh_tasked
    tasked_exercise.refresh_tasked = nil
    task.task_steps << refresh_step
    refresh_step.save!

    transfer_errors_from(refresh_step, type: :verbatim)
  end
end
