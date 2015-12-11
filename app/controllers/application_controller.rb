class ApplicationController < ActionController::Base

  respond_to :html, :js

  include Lev::HandleWith

  before_filter :authenticate_user!

  protected

  def require_contracts
    contract_names = current_users_contracts
    profile = current_user.to_model

    contract_names.proxy_signed.each do |name|
      next if FinePrint.signed_contract?(profile, name)

      FinePrint.sign_contract(profile, name, FinePrint::SIGNATURE_IS_IMPLICIT)
    end

    if contract_names.non_proxy_signed.any?
      fine_print_require *contract_names.non_proxy_signed
    end
  end

  def current_users_contracts
    # Get contracts that apply to the user's current courses; some of these
    # have been signed by proxy (and need an implicit signature), while some
    # don't and need to go through the normal FinePrint process.
    courses = GetUserCourses.call(user: current_user).courses
    Legal::GetContractNames.call(
      applicable_to: courses,
      contract_names_signed_by_everyone: [:general_terms_of_use, :privacy_policy]
    )
  end

  def allow_iframe_access
    response.headers.except! 'X-Frame-Options'
  end

end
