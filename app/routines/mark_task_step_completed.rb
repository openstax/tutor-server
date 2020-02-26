class MarkTaskStepCompleted
  lev_routine transaction: :read_committed

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders

  protected

  def exec(task_step:, completed_at: Time.current, lock_task: true, save: true)
    task = task_step.task
    if lock_task && task.persisted?
      task.save!
      task.lock!
    end

    task_step.complete completed_at: completed_at
    transfer_errors_from task_step, { type: :verbatim }, true

    return unless errors.empty?

    task_step.save! if save

    run(:populate_placeholders, task: task, lock_task: false) if task.core_task_steps_completed?

    return unless save && task_step.exercise?

    course = task.taskings.first&.role&.student&.course
    return if course.nil?

    OpenStax::Biglearn::Api.record_responses course: course, tasked_exercise: task_step.tasked
  end
end
