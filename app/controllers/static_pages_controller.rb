class StaticPagesController < ApplicationController

  respond_to :html

  skip_before_filter :authenticate_user!,
                     only: [:about, :contact, :contact_form, :copyright, :developers,
                            :help, :privacy, :share, :status, :terms, :omniauth_failure,
                            :signup]

  before_filter :use_openstax_logo

  # GET /status
  # Used by AWS (and others) to make sure the site is still up
  def status
    head :ok
  end

  def contact_form
    render text: "<h1 style='line-height: 300px;text-align: center'>Sorry, delivering messages from the contact form is not yet implemented</h1>"
  end

  def omniauth_failure
    flash[:error] = "Authentication failure #{params[:message]}"
    redirect_to root_path
  end

  def use_openstax_logo
    @use_openstax_logo = true
  end
end
