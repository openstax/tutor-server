module ContentAnalyst
  class JobsController < BaseController
    include Manager::JobActions

    self.job_url_proc = ->(job) { content_analyst_job_path(job.id) }
  end
end
