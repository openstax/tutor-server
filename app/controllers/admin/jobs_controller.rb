module Admin
  class JobsController < BaseController
    include Manager::JobActions

    self.job_search_url_proc = -> { admin_jobs_path }
    self.job_url_proc = ->(job) { admin_job_path(job.id) }
  end
end
