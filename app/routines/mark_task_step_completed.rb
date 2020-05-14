class MarkTaskStepCompleted
  lev_routine transaction: :read_committed

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders

  include Ratings::Concerns::RatingJobs

  protected

  def exec(task_step:, completed_at: Time.current, lock_task: true, save: true)
    step_completed_at = completed_at
    task = task_step.task
    if lock_task && task.persisted?
      task.save!
      task.lock!
    end

    task_was_completed = task.completed?(use_cache: true)

    task_step.complete completed_at: step_completed_at
    transfer_errors_from task_step, { type: :verbatim }, true

    return unless errors.empty?

    if save
      task_step.save!
      task.save!
    end

    run(:populate_placeholders, task: task, lock_task: false) if task.core_task_steps_completed?

    return unless save && task_step.exercise?

    role = task.taskings.first&.role
    period = role&.course_member&.period
    course = period&.course
    # course will only be set if role and period were found
    return if course.nil?

    OpenStax::Biglearn::Api.record_responses course: course, tasked_exercise: task_step.tasked

    return if task_was_completed

    perform_rating_jobs_later task: task, role: role, period: period, current_time: completed_at
  end
end
