class MarkTaskStepCompleted

  lev_routine

  protected

  def exec(task_step:, completion_time: Time.current)
    # Pessimistic locking to prevent race conditions with the update logic
    task_step.lock!

    # The task_step save causes the task to be updated (touched), as required for the lock to work
    task_step.complete(completion_time: completion_time).save
    transfer_errors_from(task_step, {type: :verbatim}, true)

    tasked = task_step.tasked
    tasked.try(:handle_task_step_completion!)
    transfer_errors_from(tasked, {type: :verbatim}, true)

    task = task_step.task
    task.handle_task_step_completion!(completion_time: completion_time)
    transfer_errors_from(task, {type: :verbatim}, true)

    course = task.taskings.first.try!(:role).try!(:student).try!(:course)
    OpenStax::Biglearn::Api.record_responses(course: course, tasked_exercise: tasked) \
      unless course.nil?
  end

end
