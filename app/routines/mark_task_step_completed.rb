class MarkTaskStepCompleted

  lev_routine

  protected

  def exec(task_step:)
    fatal_error(code: :step_type_cannot_be_marked_completed) \
      unless %w(TaskedReading TaskedExercise TaskedVideo).include?(task_step.tasked_type)

    task_step.complete
    task_step.save

    transfer_errors_from(task_step, {type: :verbatim}, true)
  end

end