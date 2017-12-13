# This is the only controller that allows CORS for a section user
# API controllers only allow CORS if using an access token
# We rely on the origin checking to prevent unauthorized sites from getting the user access token
class AuthController < ApplicationController

  # If a user's signed in make sure they've agreed to contracts
  before_filter :require_contracts, only: [ :iframe, :popup ],
                                    unless: -> { current_user.is_anonymous? }

  # Allow accessing iframe methods from inside an iframe
  before_filter :allow_iframe_access, only: [:logout]

  # Methods handle returning login status differently than the standard authenticate_user! filter
  skip_before_filter :authenticate_user!, only: [:status, :popup, :logout]

  # CRSF tokens can't be used since these endpoints are loaded from foreign sites via cors or iframe
  skip_before_action :verify_authenticity_token, only: [:status, :popup, :logout]

  layout false

  def status
    render json: user_status_update
  end

  def popup
    if current_user.is_anonymous?
      redirect_to_login_url
    else
      require_contracts
      @status = user_status_update
      @parent_window = params[:parent]
    end
  end

  def logout
    sign_out!

    redirect_to OpenStax::Utilities.generate_url(
                  OpenStax::Accounts.configuration.openstax_accounts_url,
                  "logout", parent: params[:parent]
                ) unless stubbed_auth?
  end

  private

  def stubbed_auth?
    OpenStax::Accounts.configuration.enable_stubbing?
  end

  def user_status_update
    status = strategy.authorize.body.slice('access_token')
    status = status.merge Api::V1::BootstrapDataRepresenter.new(current_user).to_hash(
                            user_options: { tutor_api_url: api_root_url }
                          ) if !current_user.is_anonymous? && ( stubbed_auth? || terms_agreed? )
    status[:endpoints] = {
      is_stubbed: stubbed_auth?,
      login:  auth_authenticate_via_popup_url,
      logout: auth_logout_via_popup_url,
      accounts_iframe: stubbed_auth? ? auth_authenticate_via_popup_url :
        OpenStax::Utilities.generate_url(
          OpenStax::Accounts.configuration.openstax_accounts_url, "remote/iframe"
        )
    }
    status
  end

  def terms_agreed?
    GetUserTermsInfos[current_user].reject(&:is_signed).empty?
  end

  def strategy
    @strategy ||= Doorkeeper::Server.new(self).token_request 'session'
  end

  def redirect_to_login_url
    store_url key: :accounts_return_to, strategies: [:session]
    if stubbed_auth?
      redirect_to openstax_accounts.dev_accounts_url
      session[:parent] = params[:parent]
    else
      redirect_to openstax_accounts.login_url(go: params[:go])
    end
  end

end
