class AuthController < ApplicationController

  before_filter :set_cors_headers, only: [:status, :cors_preflight_check]

  # iframe_start doesn't need to clear the headers since doesn't render, it only redirects
  before_filter :allow_iframe_access, only: [:iframe_start, :iframe_finish]

  #before_filter :forbid_access
  # these should always return 200 response regardless of login status
  skip_before_filter :authenticate_user!, only: [:status, :cors_preflight_check, :iframe_start, :iframe_finish]



  # Since these endpoints are loaded from foreign sites via cors or iframe, CRSF tokens can't be used
  skip_before_action :verify_authenticity_token

  def status
    render json: user_status_update
  end

  # requested by an OPTIONS request type
  def cors_preflight_check # the other CORS headers are set by the before_filter
    headers['Access-Control-Max-Age'] = '1728000'
    render text: '', :content_type => 'text/plain'
  end

  def iframe_start
    if current_user.is_anonymous?
      session[:accounts_return_to] = after_iframe_authentication_url
      redirect_to openstax_accounts.login_url #(host_only:false)
    else
      @status = user_status_update
      render action: :iframe_finish
    end
  end

  def iframe_finish
    head :forbidden and return if current_user.is_anonymous?
    # the view will deliver the status data using postMessage out of the iframe
    @status = user_status_update
  end

  private

  def user_status_update
    status = strategy.authorize.body.slice('access_token')
    unless current_user.is_anonymous?
      status[:current_user] = Api::V1::UserRepresenter.new(current_user)
    end
    status[:endpoints] = {
      login: openstax_accounts.login_url,
      iframe_login: authenticate_via_iframe_url,
      accounts_iframe: Rails.application.secrets.openstax['accounts']['url'] + "/remote/iframe"
    }
    status
  end

  def allow_iframe_access
    response.headers.except! 'X-Frame-Options'
  end

  def set_cors_headers
    headers['Access-Control-Allow-Origin']   = validated_cors_origin
    headers['Access-Control-Allow-Methods']  = 'GET, OPTIONS' # No PUT/POST access
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Credentials'] = 'true'
    headers['Access-Control-Allow-Headers']  = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  def strategy
    @strategy ||= server.token_request 'session'
  end

  def server
    @server ||= Doorkeeper::Server.new(self)
  end

  def validated_cors_origin
    OpenStax::Api.configuration.validate_cors_origin[ request ] ? request.headers["HTTP_ORIGIN"] : ''
  end

end
