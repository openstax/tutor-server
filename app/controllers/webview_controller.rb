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
    # have been signed by proxy.  Take care of those first.

    targeted_contracts = GetCourseTargetedContractsForUser[user: current_user]

    proxy_signed_contracts, non_proxy_signed_contracts =
      targeted_contracts.partition(&:is_proxy_signed)

    proxy_signed_contracts.each do |contract|
      next if FinePrint.signed_contract?(current_user, contract.contract_name)

      FinePrint.sign_contract(current_user,
                              contract.name,
                              FinePrint::SIGNATURE_IS_IMPLICIT)
    end

    # Figure out which remaining contracts need to be signed and then have
    # FinePrint take care of it.

    contracts_signed_by_everyone =
      [:general_terms_of_use, :privacy_policy]

    contracts_masked_by_targeted_contracts =
      targeted_contracts.collect(&:masked_contract_names)
                        .flatten.compact.uniq

    targeted_contracts_without_proxy_signature =
      non_proxy_signed_contracts.collect(&:contract_name)
                                .flatten.compact.uniq

    fine_print_require *(

      ( contracts_signed_by_everyone -
        contracts_masked_by_targeted_contracts ) +
      targeted_contracts_without_proxy_signature

    )
  end

end
