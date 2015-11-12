class AuthController < ApplicationController

  before_filter :require_contracts, only: :iframe, unless: -> { current_user.is_anonymous? }

  # Unlike other controllers, these cors headers allows cookies via the
  # Access-Control-Allow-Credentials header
  before_filter :set_cors_headers, only: [:status, :cors_preflight_check, :logout]

  # Allow accessing iframe methods from inside an iframe
  before_filter :allow_iframe_access, only: [:iframe]

  # Methods handle returning login status differently than the standard authenticate_user! filter
  skip_before_filter :authenticate_user!,
                     only: [:status, :cors_preflight_check, :iframe, :logout]

  # CRSF tokens can't be used since these endpoints are loaded from foreign sites via cors or iframe
  skip_before_action :verify_authenticity_token,
                     only: [:status, :cors_preflight_check, :iframe, :logout]

  layout false

  def status
    render json: user_status_update
  end

  # requested by an OPTIONS request type
  def cors_preflight_check # the other CORS headers are set by the before_filter
    headers['Access-Control-Max-Age'] = '1728000'
    render text: '', :content_type => 'text/plain'
  end

  def iframe
    if current_user.is_anonymous?
      redirect_to_login_url
    else
      @status = user_status_update
      @iframe_origin = stubbed_auth? ? session[:parent] : @status[:endpoints][:accounts_iframe]
    end
  end

  def logout
    if current_user.is_anonymous?
      render status: :forbidden, text: 'You must be logged in to logout'
    else
      sign_out!
      render json: { logout: true }
    end
  end

  private

  def stubbed_auth?
    OpenStax::Accounts.configuration.enable_stubbing?
  end

  def user_status_update
    status = strategy.authorize.body.slice('access_token')
    unless current_user.is_anonymous?
      status.merge! Api::V1::UserBootstrapDataRepresenter.new(current_user)
    end
    status[:endpoints] = {
      login: openstax_accounts.login_url,
      iframe_login: authenticate_via_iframe_url,
      accounts_iframe: stubbed_auth? ?
        authenticate_via_iframe_url :
        Rails.application.secrets.openstax['accounts']['url'] + "/remote/iframe"
    }
    status
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin']   = validated_cors_origin
    headers['Access-Control-Allow-Methods']  = 'GET, OPTIONS, DELETE' # No PUT/POST access
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Allow-Headers']  = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def strategy
    @strategy ||= Doorkeeper::Server.new(self).token_request 'session'
  end

  def validated_cors_origin
    OpenStax::Api.configuration.validate_cors_origin[ request ] ? request.headers["HTTP_ORIGIN"] : ''
  end

  def redirect_to_login_url
    store_url key: :accounts_return_to, strategies: [:session]
    if stubbed_auth?
      redirect_to openstax_accounts.dev_accounts_url
      session[:parent] = params[:parent]
    else
      redirect_to openstax_accounts.login_url
    end
  end

end
