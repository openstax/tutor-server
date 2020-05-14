module Ratings::Concerns::RatingJobs
  def perform_rating_jobs_later(task:, role:, period:, current_time: Time.current)
    anti_cheating_date = [ current_time, task.due_at, task.feedback_at ].compact.max
    is_past_anti_cheating_date = anti_cheating_date <= current_time
    task_is_completed = task.completed?(use_cache: true)

    # Student scores will be updated at the anti-cheat-date (probably due-date) regardless of if
    # they are complete or not. Additional work done after due-date will cause a recalculation only
    # if the entire assignment is completed.

    # Period scores (that the teacher sees) will be updated at student assignment completion, and
    # at anti-cheat-date for incomplete assignments only: completed assignments will have already
    # been calculated. Late work also only recalculates if assignment is completed.

    # We have written the delayed-job calculation to be reentrant - that means that if an extra job
    # runs, it will notice that there is no work to do, and do nothing.

    if is_past_anti_cheating_date
      return if !task_is_completed

      should_queue_role_job = true
      should_queue_period_job = true

      role_run_at = current_time
      period_run_at = current_time
    else
      should_queue_role_job = !Delayed::Job.where(id: task.role_book_part_job_id).exists?

      if task_is_completed
        should_queue_period_job = true

        role_run_at = anti_cheating_date
        period_run_at = current_time
      else
        should_queue_period_job = !Delayed::Job.where(id: task.period_book_part_job_id).exists?

        role_run_at = anti_cheating_date
        period_run_at = anti_cheating_date
      end
    end

    queue = task.is_preview ? 'preview' : 'dashboard'

    # We determined that the period update normally runs first
    # so we queue it first here to keep the order consistent in specs
    Ratings::UpdatePeriodBookParts.set(queue: queue).perform_later(
      period: period, task: task
    ) if should_queue_period_job && role.student?

    Ratings::UpdateRoleBookParts.set(queue: queue, run_at: role_run_at).perform_later(
      role: role, task: task
    ) if should_queue_role_job
  end
end
