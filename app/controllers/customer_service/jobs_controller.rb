module CustomerService
  class JobsController < BaseController
    include Manager::JobActions

    self.job_search_url_proc = -> { customer_service_jobs_path }
    self.job_url_proc = ->(job) { customer_service_job_path(job.id) }
  end
end
