# https://github.com/rails/rails/commit/dd8e859829bfcfd8cb0287ce804055b827a35af1
# Remove when upgrading to Rails 5

module ActiveJob::Core
  # ID optionally provided by adapter
  attr_accessor :provider_job_id
end

class ActiveJob::QueueAdapters::DelayedJobAdapter
  def enqueue(job) #:nodoc:
    delayed_job = Delayed::Job.enqueue(JobWrapper.new(job.serialize), queue: job.queue_name)
    job.provider_job_id = delayed_job.id
    delayed_job
  end

  def enqueue_at(job, timestamp) #:nodoc:
    delayed_job = Delayed::Job.enqueue(JobWrapper.new(job.serialize), queue: job.queue_name, run_at: Time.at(timestamp))
    job.provider_job_id = delayed_job.id
    delayed_job
  end
end
