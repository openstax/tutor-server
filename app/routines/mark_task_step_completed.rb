class MarkTaskStepCompleted

  lev_routine

  protected

  def exec(task_step:)
    fatal_error(code: :step_type_cannot_be_marked_completed) \
      unless %w(TaskedReading TaskedInteractive TaskedExercise).include?(task_step.tasked_type)

    task_step.update_attributes(completed_at: Time.now)

    transfer_errors_from(task_step, {type: :verbatim}, true)
  end

end