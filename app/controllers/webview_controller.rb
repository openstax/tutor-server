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
    # Get contracts that apply to the user's current courses; some of these
    # have been signed by proxy (and need an implicit signature), while some
    # don't and need to go through the normal FinePrint process.

    courses = GetUserCourses[user: current_user.user]

    contract_names = Legal::GetContractNames.call(
      applicable_to: courses,
      contract_names_signed_by_everyone: [:general_terms_of_use, :privacy_policy]
    ).outputs

    contract_names.proxy_signed.each do |name|
      next if FinePrint.signed_contract?(current_user, name)

      FinePrint.sign_contract(current_user,
                              name,
                              FinePrint::SIGNATURE_IS_IMPLICIT)
    end

    if contract_names.non_proxy_signed.any?
      fine_print_require *contract_names.non_proxy_signed
    end
  end

end
