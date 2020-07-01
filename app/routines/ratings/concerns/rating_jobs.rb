module Ratings::Concerns::RatingJobs
  def perform_rating_jobs_later(
    task:,
    role:,
    period:,
    event:,
    lock_task: true,
    wait: false,
    current_time: Time.current,
    queue: nil
  )
    task.lock! if lock_task

    # Student ratings will be updated at the due-date regardless of if they are complete or not.
    # So when the first step is completed in an assignment we queue up Glicko to run at the due date
    # (unless the assignment has only 1 step and immediate feedback).
    # Additional work done after due-date will cause a recalculation
    # only if the entire assignment is completed.

    # Period ratings (that the teacher sees) will be updated when the assignment is completed,
    # and at the due date for incomplete assignments only: completed assignments will have already
    # been calculated. Late work also only recalculates if assignment is completed.

    # We have written the delayed_job calculation to be reentrant - that means that if an extra job
    # runs, it will notice that there is no work to do, and do nothing.

    if task.due_at.nil? || task.past_due?(current_time: current_time)
      # Additional work done after the due date will cause a recalculation
      # only if the entire assignment is completed.
      # Grading or publishing grades (if applicable) may also cause a recalculation
      # when the entire assignment is graded and/or published.
      case event
      when :work
        return unless task.completed?(use_cache: true)
      when :grade
        return unless task.manual_grading_complete?
      when :migrate
        return unless task.completed?(use_cache: true) || task.manual_grading_complete?
      end

      run_role_job = :now
      run_period_job = :now
    else
      if task.completed?(use_cache: true)
        # The period update always runs immediately when the assignment is first completed.
        run_period_job = :now

        if task.auto_grading_feedback_available?
          # If immediate feedback is available, we run the role update immediately
          run_role_job = :now
        else
          # If immediate feedback is not available, we run the role update at the due date
          # (only if not queued yet)
          run_role_job = :due
        end
      else
        # Queue role and period jobs to run at the due date, but only if not queued yet
        run_role_job = :due
        run_period_job = :due
      end
    end

    queue ||= task.preview_course? ? 'preview' : 'dashboard'

    # We determined that the period update normally runs first
    # so we queue it first here to keep the order consistent in specs
    # Don't run the period job for teacher_students
    if role.student?
      case run_period_job
      when :now
        Ratings::UpdatePeriodBookParts.set(queue: queue).perform_later(
          period: period, task: task, wait: wait
        )
      when :due
        # Glicko requires real background jobs to be turned on to behave properly
        # We keep the due date job id in the task record to prevent queuing too many useless jobs
        unless Delayed::Job.where(id: task.period_book_part_job_id).exists?
          job = Ratings::UpdatePeriodBookParts.set(queue: queue, run_at: task.due_at).perform_later(
            period: period, task: task, wait: wait
          )

          task.period_book_part_job_id = job&.provider_job_id
        end
      end
    end

    case run_role_job
    when :now
      Ratings::UpdateRoleBookParts.set(queue: queue).perform_later(
        role: role, task: task, wait: wait
      )
    when :due
      # Glicko requires real background jobs to be turned on to behave properly
      # We keep the due date job id in the task record to prevent queuing too many useless jobs
      unless Delayed::Job.where(id: task.role_book_part_job_id).exists?
        Ratings::UpdateRoleBookParts.set(queue: queue, run_at: task.due_at).perform_later(
          role: role, task: task, wait: wait
        )

        task.role_book_part_job_id = job&.provider_job_id
      end
    end

    task.save validate: false
  end
end
