class ApplicationController < ActionController::Base

  respond_to :html, :js

  include Lev::HandleWith

  WEBVIEW_FLASH_TYPES = [:webview_notice]

  add_flash_types *WEBVIEW_FLASH_TYPES
  prepend_before_filter :keep_webview_flash

  before_filter :block_sign_up
  before_filter :authenticate_user!

  protected

  def block_sign_up
    # Must be called before `authenticate_user!`
    login_params[:signup_at] = signup_url
  end

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
    courses = GetUserCourses[user: current_user]
    Legal::GetContractNames.call(
      applicable_to: courses,
      contract_names_signed_by_everyone: [:general_terms_of_use, :privacy_policy]
    ).outputs
  end

  def allow_iframe_access
    response.headers.except! 'X-Frame-Options'
  end

  def keep_webview_flash
    # keep webview flash notices until they are explicitly removed (i.e. when
    # they are actually conveyed to the webview), helps us get past intermediate
    # pages like the Terms of Use agreement pages.

    WEBVIEW_FLASH_TYPES.each do |webview_flash_type|
      flash.keep(webview_flash_type)
    end
  end

  def convert_and_clear_webview_flash
    # When this method is called we want to convert the special `webview_foo`
    # flash info to just `foo` flash info and then stop keeping the `webview_`
    # variant.

    WEBVIEW_FLASH_TYPES.each do |webview_flash_type|
      normal_flash_type = webview_flash_type.to_s.gsub(/webview_/,'').to_sym
      flash[normal_flash_type] = flash[webview_flash_type] if flash[webview_flash_type].present?
      flash.delete(webview_flash_type)
    end
  end

end
