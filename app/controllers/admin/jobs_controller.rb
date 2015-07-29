require 'will_paginate/array'

class Admin::JobsController < ApplicationController
  def index
    @page_header = "Queued jobs"
    @jobs = Lev::Status.jobs.paginate(page: params[:page], per_page: 20)
  end
end
