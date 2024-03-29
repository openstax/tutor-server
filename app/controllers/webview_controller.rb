class WebviewController < ApplicationController
  respond_to :html

  layout :resolve_layout

  before_action :check_supported_browser
  skip_before_action :authenticate_user!, only: [ :home, :enroll ]

  def home
    if params[:cc] == "1"
      redirect_to 'http://cc.openstax.org'
    elsif current_user.is_signed_in?
      redirect_to dashboard_path
    end

    @homepage = HOMEPAGE_CONFIG[:new_subjects]
  end

  def index
  end

  def enroll
    period = CourseMembership::GetPeriod[ enrollment_code: params[:enroll_token] ]
    @does_cost = period ? period.course.does_cost : false
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
