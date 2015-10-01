module CustomerService
  class JobsController < BaseController
    include Manager::JobActions

    self.job_url_proc = ->(job) { customer_service_job_path(job.id) }
  end
end
