# This is the only controller that allows CORS for a section user
# API controllers only allow CORS if using an access token
# We rely on the origin checking to prevent unauthorized sites from getting the user access token
class AuthController < ApplicationController

  before_filter :require_contracts, only: :iframe, unless: -> { current_user.is_anonymous? }

  # Unlike other controllers, these cors headers allows cookies via the
  # Access-Control-Allow-Credentials header
  before_filter :set_cors_headers, only: [:status, :cors_preflight_check, :logout]

  # If a user's signed in make sure they've agreed to contracts
  before_filter :require_contracts, only: :popup, unless: -> { current_user.is_anonymous? }

  # Allow accessing iframe methods from inside an iframe
  before_filter :allow_iframe_access, only: [:logout]

  # Methods handle returning login status differently than the standard authenticate_user! filter
  skip_before_filter :authenticate_user!,
                     only: [:status, :cors_preflight_check, :popup, :logout]

  # CRSF tokens can't be used since these endpoints are loaded from foreign sites via cors or iframe
  skip_before_action :verify_authenticity_token,
                     only: [:status, :cors_preflight_check, :popup, :logout]

  layout false

  # Requested by an OPTIONS request type
  def cors_preflight_check # the other CORS headers are set by the before_filter
    headers['Access-Control-Max-Age'] = '1728000'
    render text: '', content_type: 'text/plain'
  end

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

  def set_cors_headers
    headers['Access-Control-Allow-Origin']   = validated_cors_origin
    headers['Access-Control-Allow-Methods']  = 'GET, OPTIONS' # No PUT/POST/DELETE access
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Allow-Headers']  = 'Origin, X-Requested-With, ' +
                                               'Content-Type, Accept, Authorization'
  end

  def strategy
    @strategy ||= Doorkeeper::Server.new(self).token_request 'session'
  end

  def validated_cors_origin
    OpenStax::Api.configuration.validate_cors_origin[request] ? request.headers["HTTP_ORIGIN"] : ''
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
