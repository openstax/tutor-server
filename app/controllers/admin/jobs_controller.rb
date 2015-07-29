require 'will_paginate/array'

module Admin
  class JobsController < BaseController
    def index
      @page_header = "Queued jobs"
      @jobs = Lev::Status.all.paginate(page: params[:page], per_page: 20)
    end
  end
end
