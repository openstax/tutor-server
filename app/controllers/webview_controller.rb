class WebviewController < ApplicationController
  include Hypothesis

  respond_to :html

  layout :resolve_layout

  before_action :check_supported_browser
  skip_before_action :authenticate_user!, only: [:home, :enroll, :cors_preflight_check]

  # Requested by an OPTIONS request type
  def cors_preflight_check # the other CORS headers are set by the before_action
    headers['Access-Control-Max-Age'] = '1728000'
    headers['Access-Control-Allow-Origin'] = Rails.application.secrets.hypothesis[:client_url]
    render text: '', content_type: 'text/plain'
  end

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

  def check_supported_browser
    redirect_to browser_upgrade_path(go: current_url) unless params.has_key?(:ignore_browser) || browser.modern?
    true
  end

end
