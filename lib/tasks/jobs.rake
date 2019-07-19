def job_time_range(relation, field, current_time)
  minimum = relation.minimum field
  return 'N/A' if minimum.nil?

  maximum = relation.maximum field
  return 'N/A' if maximum.nil?

  min_time = (current_time - minimum).to_i.abs
  max_time = (current_time - maximum).to_i.abs

  chosen_unit = 'second(s)'
  { 'day(s)': 60*60*24, 'hour(s)': 60*60, 'minute(s)': 60 }.each do |unit, quotient|
    next unless min_time > quotient && max_time > quotient

    min_time = min_time/quotient
    max_time = max_time/quotient
    chosen_unit = unit
    break
  end

  return "#{min_time} #{chosen_unit}" if min_time == max_time

  min_max = [min_time, max_time].sort

  "#{min_max[0]} to #{min_max[1]} #{chosen_unit}"
end

def job_last_error(job, backtrace_lines)
  return 'N/A' if job.nil? || job.last_error.nil?

  errors = job.last_error.split("\n")
  errors = errors.first(backtrace_lines) unless backtrace_lines.nil?
  errors.join("\n  ")
end

namespace :jobs do
  desc 'Marks all failed jobs as not failed'
  task :unfail, [] => :log_to_stdout do
    failed = Delayed::Job.where.not(failed_at: nil).update_all(failed_at: nil)

    Rails.logger.info { "Unfailed #{failed} job(s)" }
  end

  desc 'Make all waiting to retry jobs retry immediately'
  task :retry_now, [] => :log_to_stdout do
    dj = Delayed::Job.arel_table
    current_time = Time.current

    waiting = Delayed::Job.where(failed_at: nil).where(
      dj[:attempts].gt(0).and(dj[:run_at].gt(current_time))
    ).update_all(run_at: current_time)

    Rails.logger.info { "Moved #{waiting} job(s) waiting to retry to queue" }
  end

  desc 'Prints summary information about background jobs'
  task :status, [:full_backtrace] => :log_to_stdout do |task, args|
    current_time = Time.current
    timeout_time = current_time - Delayed::Worker.max_run_time
    dj = Delayed::Job.arel_table

    not_failed_jobs = Delayed::Job.where(failed_at: nil)
    waiting_jobs = not_failed_jobs.where(dj[:run_at].gt(current_time))
    waiting_to_run = waiting_jobs.where(attempts: 0).count
    waiting_to_retry = waiting_jobs.where(dj[:attempts].gt(0)).count
    wait_range = job_time_range waiting_jobs, :run_at, current_time
    ready_jobs = not_failed_jobs.where(dj[:run_at].lteq(current_time))
    queued_jobs = ready_jobs.where(locked_by: nil).or(
      ready_jobs.where(locked_at: nil).or(
        ready_jobs.where(dj[:locked_at].lteq(timeout_time))
      )
    )
    queued = queued_jobs.count
    queued_range = job_time_range queued_jobs, :run_at, current_time
    running_jobs = ready_jobs.where.not(locked_by: nil).where(
      dj[:locked_at].gt(timeout_time)
    )
    running = running_jobs.count
    running_range = job_time_range running_jobs, :locked_at, current_time
    failed_jobs = Delayed::Job.where.not(failed_at: nil)
    failed = failed_jobs.count
    failed_range = job_time_range failed_jobs, :failed_at, current_time
    backtrace_lines = args[:full_backtrace] ? nil : 3
    last_retry_error = job_last_error not_failed_jobs.order(:updated_at).last, backtrace_lines
    last_failure_error = job_last_error failed_jobs.order(:failed_at).last, backtrace_lines
    failed_by_attempts = failed_jobs.group(:attempts).count
    errors = Delayed::Job.where(dj[:attempts].gt(0))
                         .group(:attempts)
                         .count
                         .sort
                         .map do |attempts, count|
      num_failed = failed_by_attempts.fetch(attempts, 0)
      failed_text = num_failed == 0 ? '' : " (#{num_failed} failed)"

      "\n  #{count} job(s) errored #{attempts} time(s)#{failed_text}"
    end.join
    retries = ' N/A' if retries.blank?

    Rails.logger.info do
      <<~STATUS
        Waiting to run: #{waiting_to_run}
        Waiting to retry: #{waiting_to_retry}
        Waiting for: #{wait_range}
        Queued: #{queued}
        Queued for: #{queued_range}
        Running/Locked: #{running}
        Running/Locked for: #{running_range}
        Failed: #{failed}
        Failed for: #{failed_range}
        Errors:#{errors}

        Last error that caused a retry: #{last_retry_error}

        Last error that caused a failure: #{last_failure_error}
      STATUS
    end
  end
end
