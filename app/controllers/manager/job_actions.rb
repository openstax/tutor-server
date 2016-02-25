require 'will_paginate/array'

module Manager::JobActions
  def self.included(base)
    base.class_attribute :job_url_proc
  end

  def index
    @jobs = Jobba.all.to_a
    @job_url_proc = job_url_proc
    render 'manager/jobs/index'
  end

  def show
    @job = Jobba.find(params[:id])
    @custom_fields = @job.data || {}
    render 'manager/jobs/show'
  end
end
