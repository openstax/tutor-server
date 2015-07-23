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

  def require_contracts
    # contracts = GetApplicableContracts[user: current_user]
    # fine_print_require *contracts

    fine_print_require :general_terms_of_use, :privacy_policy
  end

end
