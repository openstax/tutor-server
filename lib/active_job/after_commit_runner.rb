# http://blog.arkency.com/2015/10/run-it-in-background-job-after-commit/
# This class will attempt to reserve the Delayed::Job associated with the given ActiveJob
# and run it as soon as the current transaction commits, if it was successfully reserved
# If this is the same transaction that created the Delayed::Job, the reserve step should never fail
# If there is no ongoing transaction, the Delayed::Job is run immediately, if reserved successfully
class ActiveJob::AfterCommitRunner
  def initialize(active_job, inline_job_timeout = Delayed::Worker.max_run_time)
    @delayed_job = reserve_and_return_delayed_job(active_job, inline_job_timeout)
  end

  def has_transactional_callbacks?
    !@delayed_job.nil?
  end

  def committed!(*_)
    delayed_worker.run(@delayed_job) if has_transactional_callbacks?
  end

  def rolledback!(*_)
  end

  def set_transaction_state(state)
  end

  def run_after_commit
    if ActiveRecord::Base.connection.transaction_open?
      ActiveRecord::Base.connection.current_transaction.add_record self
    else
      committed!
    end
  end

  protected

  def delayed_worker
    Thread.current[:delayed_worker] ||= Delayed::Worker.new
  end

  def reserve_and_return_delayed_job(active_job, inline_job_timeout)
    delayed_job_id = active_job.provider_job_id

    return if delayed_job_id.nil?

    # Lock the Biglearn request job so we can run it inline to speed up Biglearn responses
    ready_scope = Delayed::Job.ready_to_run(delayed_worker.name, Delayed::Worker.max_run_time)
                              .where(id: delayed_job_id)
    # Pretend the lock is much closer to expiring so we get a shorter timeout
    now = Delayed::Job.db_time_now - Delayed::Worker.max_run_time + inline_job_timeout

    # We just created the job and are still inside the same transaction,
    # so the lock should never fail (PostgreSQL doesn't even support Read Uncommitted)
    Delayed::Job.reserve_with_scope(ready_scope, delayed_worker, now)
  end
end
