class CollectJobsData
  lev_routine

  protected

  # This routine assumes delayed_job is being used
  def exec(job_name:)
    jobs = Jobba.where(job_name: job_name).to_a

    delayed_job_ids = jobs.map(&:provider_job_id)
    existing_delayed_jobs = Set.new Delayed::Job.where(id: delayed_job_ids).pluck(:id, :failed_at)
    existing_delayed_job_ids = existing_delayed_jobs.map(&:first)
    failed_delayed_jobs = existing_delayed_jobs.select { |id, failed_at| !failed_at.nil? }
    failed_delayed_job_ids = Set.new failed_delayed_jobs.map(&:first)

    not_completed_jobs, outputs.completed_jobs = jobs.partition do |job|
      existing_delayed_job_ids.include? job.provider_job_id
    end

    outputs.failed_jobs, outputs.incomplete_jobs = not_completed_jobs.partition do |job|
      failed_delayed_job_ids.include? job.provider_job_id
    end
  end
end
