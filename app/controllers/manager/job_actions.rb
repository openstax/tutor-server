require 'will_paginate/array'

module Manager::JobActions
  def self.included(base)
    base.class_attribute :job_search_url_proc
    base.class_attribute :job_url_proc
  end

  def index
    @page = params.fetch(:page, 1).to_i
    @per_page = params.fetch(:per_page, 100).to_i
    @state = params.fetch(:state, 'all')
    @total = Jobba.all.count
    rel = @state == 'all' ? Jobba.all : Jobba.where(state: @state)
    @jobs = rel.limit(@per_page).offset((@page - 1) * @per_page).to_a
    @job_search_url = instance_exec(&job_search_url_proc)
    @job_url_proc = job_url_proc
    render 'manager/jobs/index'
  end

  def show
    @job = Jobba.find(params[:id])
    raise ActionController::RoutingError.new('Not Found') if @job.nil?
    @custom_fields = @job.data || {}
    render 'manager/jobs/show'
  end
end
