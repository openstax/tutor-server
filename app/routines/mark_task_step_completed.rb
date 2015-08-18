class MarkTaskStepCompleted

  lev_routine

  protected

  def exec(task_step:, completion_time: Time.now)
    # Pessimistic locking to prevent race conditions with the update logic
    task_step.lock!

    # Get the task after the reload so we have its updated state
    task = task_step.task

    task_step.complete(completion_time: completion_time)
    task_step.save
    transfer_errors_from(task_step, {type: :verbatim}, true)

    task_step.tasked.try(:handle_task_step_completion!)
    transfer_errors_from(task_step.tasked, {type: :verbatim}, true)

    task.handle_task_step_completion!(completion_time: completion_time)
    transfer_errors_from(task, {type: :verbatim}, true)
  end

end
