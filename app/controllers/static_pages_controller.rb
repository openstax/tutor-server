class StaticPagesController < ApplicationController
  
  respond_to :html

  skip_before_filter :authenticate_user!,
                     only: [:about, :contact, :copyright, :developers,
                            :help, :privacy, :share, :status, :terms]
  fine_print_skip :general_terms_of_use, :privacy_policy,
                  only: [:about, :contact, :copyright, :developers,
                         :help, :privacy, :share, :status, :terms]

  # GET /status
  # Used by AWS (and others) to make sure the site is still up
  def status
    head :ok
  end

end
