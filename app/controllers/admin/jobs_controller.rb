require 'will_paginate/array'

module Admin
  class JobsController < BaseController
    def index
      @page_header = "Queued jobs"
      @jobs = Lev::BackgroundJob.incomplete.paginate(pagination_options)
    end

    def all
      @page_header = "All jobs"
      @jobs = Lev::BackgroundJob.all.paginate(pagination_options)
      render :index
    end

    def show
      @job = Lev::BackgroundJob.find(params[:id])
      @custom_fields = @job.as_json.select do |k, _|
        !%(id progress status errors).include?(k)
      end

      @page_header = "#{@job.status.titleize} job : #{@job.id}"
    end

    private
    def pagination_options
      { page: params[:page], per_page: 20 }
    end
  end
end
