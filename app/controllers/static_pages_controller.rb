class StaticPagesController < ApplicationController
  
  respond_to :html

  skip_interceptor :authenticate_user!
  fine_print_skip :general_terms_of_use, :privacy_policy

  # GET /
  def home
  end

  # GET /about
  def about
  end

  # GET /contact
  def contact
  end

  # GET /copyright
  def copyright
  end

  # GET /developers
  def developers
  end

  # GET /help
  def help
  end

  # GET /privacy
  def privacy
  end

  # GET /share
  def share
  end

  # GET /status
  # Used by AWS (and others) to make sure the site is still up
  def status
    head :ok
  end

  # GET /tou
  def tou
  end

end
