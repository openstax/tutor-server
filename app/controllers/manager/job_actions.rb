require 'will_paginate/array'

module Manager::JobActions
  def self.included(base)
    base.class_attribute :job_url_proc
  end

  def index
    @jobs = Lev::BackgroundJob.all
    @job_url_proc = job_url_proc
    render 'manager/jobs/index'
  end

  def show
    @job = Lev::BackgroundJob.find(params[:id])
    @custom_fields = @job.as_json.select do |k, _|
      !%(id progress status errors).include?(k)
    end
    render 'manager/jobs/show'
  end
end
