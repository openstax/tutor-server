class WebviewController < ApplicationController

  respond_to :html

  layout :resolve_layout

  skip_before_filter :authenticate_user!, only: :home

  before_filter :require_contracts, only: :index

  def home
    redirect_to dashboard_path unless current_user.is_anonymous?
  end

  def index
  end

  protected

  def resolve_layout
    'home' == action_name ? false : 'webview'
  end

end
