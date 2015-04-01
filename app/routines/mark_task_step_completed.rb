class MarkTaskStepCompleted

  lev_routine

  protected

  def exec(task_step:)
    task_step.complete
    task_step.save

    transfer_errors_from(task_step, {type: :verbatim}, true)
  end

end
