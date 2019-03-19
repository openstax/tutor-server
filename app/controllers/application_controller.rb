class ApplicationController < ActionController::Base

  respond_to :html, :js

  include Lev::HandleWith

  WEBVIEW_FLASH_TYPES = [:webview_notice]

  add_flash_types *WEBVIEW_FLASH_TYPES
  prepend_before_action :keep_webview_flash

  before_action :block_sign_up, unless: -> { params[:block_sign_up].to_s == "false" }
  before_action :straight_to_student_sign_up, if: -> { params[:straight_to_student_sign_up].to_s == "true" }
  before_action :straight_to_sign_up, if: -> { params[:straight_to_sign_up].to_s == "true" }
  before_action :authenticate_user!

  protected

  def block_sign_up
    # Must be called before `authenticate_user!`
    login_params[:signup_at] = main_app.signup_url
  end

  def straight_to_student_sign_up
    # Must be called before `authenticate_user!`
    login_params[:go] = 'student_signup'
  end

  def straight_to_sign_up
    # Must be called before `authenticate_user!`
    login_params[:go] = 'signup'
  end

  def require_contracts
    unsigned_contract_names = GetUserTermsInfos[current_user].reject(&:is_signed).map(&:name)
    fine_print_require(*unsigned_contract_names) if unsigned_contract_names.any?
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
