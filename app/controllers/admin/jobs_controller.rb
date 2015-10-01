module Admin
  class JobsController < BaseController
    include Manager::JobActions

    self.job_url_proc = ->(job) { admin_job_path(job.id) }
  end
end
