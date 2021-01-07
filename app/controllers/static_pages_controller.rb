class StaticPagesController < ApplicationController
  respond_to :html

  skip_before_action :authenticate_user!, except: :stubbed_payments

  before_action :use_openstax_logo

  def contact_form
    render text: "<h1 style='line-height: 300px;text-align: center'>Sorry, delivering messages from the contact form is not yet implemented</h1>"
  end

  def omniauth_failure
    flash[:error] = "Authentication failure #{params[:message]}"
    redirect_to root_path
  end

  def stubbed_payments
    render layout: false
  end

  protected

  def use_openstax_logo
    @use_openstax_logo = true
  end
end
