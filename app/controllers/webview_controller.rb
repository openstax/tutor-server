class WebviewController < ApplicationController
  include Hypothesis

  respond_to :html

  layout :resolve_layout

  skip_before_filter :authenticate_user!, only: [:home, :enroll]

  def home
    if params[:cc] == "1"
      redirect_to 'http://cc.openstax.org'
    elsif current_user.is_signed_in?
      redirect_to dashboard_path
    end
  end

  def index
  end

  def enroll
  end

  protected

  def resolve_layout
    if ['home', 'enroll'].include? action_name
      false
    else
      # since webview layout used, get the webview flash info prepped
      convert_and_clear_webview_flash
      'webview'
    end
  end

end
