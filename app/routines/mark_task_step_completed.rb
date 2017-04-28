class MarkTaskStepCompleted

  lev_routine

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders

  protected

  def exec(task_step:, completed_at: Time.current)
    # Pessimistic locking to prevent race conditions with the update logic
    task_step.lock!

    # The task_step save in the complete! method is required for the lock to work
    task_step.complete!(completed_at: completed_at)
    transfer_errors_from(task_step, {type: :verbatim}, true)

    task = task_step.task
    course = task.taskings.first.try!(:role).try!(:student).try!(:course)
    OpenStax::Biglearn::Api.record_responses(course: course, tasked_exercise: task_step.tasked) \
      if task_step.exercise? && !task.taskings.first.try!(:role).try!(:student).try!(:course).nil?

    run(:populate_placeholders, task: task) if task.core_task_steps_completed?
  end

end
