class AuthController < ApplicationController

  # Unlike other controllers, these cors headers allows cookies via the
  # Access-Control-Allow-Credentials header
  before_filter :set_cors_headers, only: [:status, :cors_preflight_check]

  # Methods handle returning login status differently than the standard authenticate_user! filter
  skip_before_filter :authenticate_user!,
                     only: [:status, :cors_preflight_check, :login]

  # CRSF tokens can't be used since these endpoints are loaded from foreign sites via cors
  skip_before_action :verify_authenticity_token,
                     only: [:status, :cors_preflight_check, :login]

  def status
    render json: user_status_update
  end

  # requested by an OPTIONS request type
  def cors_preflight_check # the other CORS headers are set by the before_filter
    headers['Access-Control-Max-Age'] = '1728000'
    render text: '', :content_type => 'text/plain'
  end

  def login
    if current_user.is_anonymous?
      unless params[:back]
        render status: :bad_request, :text => "Missing back paramter"
        return
      end
      # Use action_interceptor to remember and retrieve back url
      store_url(url: params[:back])
      redirect_to openstax_accounts.login_url
    else
      redirect_back
    end
  end

  private

  def user_status_update
    status = strategy.authorize.body.slice('access_token')
    unless current_user.is_anonymous?
      status[:current_user] = Api::V1::UserRepresenter.new(current_user)
    end
    status[:endpoints] = {
      login: auth_start_login_url,
      accounts_iframe: Rails.application.secrets.openstax['accounts']['url'] + "/remote/iframe"
    }
    status
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
