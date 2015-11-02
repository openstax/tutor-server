class AuthController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :status
  before_filter :set_cors_headers
  skip_before_filter :authenticate_user!, only: [:status, :cors_preflight_check]

  def status

    body = strategy.authorize.body.slice('access_token')
    body[:current_user] = if current_user.is_anonymous?
                            false
                          else
                            Api::V1::UserRepresenter.new(current_user)
                          end


    render json: body
  end

  # requested by an OPTIONS request type
  def cors_preflight_check # the other CORS headers are set by the before_filter
    headers['Access-Control-Max-Age'] = '1728000'
    render text: '', :content_type => 'text/plain'
  end

  private

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

  def authorize_response
    @authorize_response ||= strategy.authorize
  end

  def server
    @server ||= Doorkeeper::Server.new(self)
  end

  def validated_cors_origin
    origin = request.headers["HTTP_ORIGIN"]
    return '' if origin.blank?
    Rails.application.secrets.cc_origins.each do | host |
      return origin if origin.match(%r{^#{host}})
    end
    '' # an empty string will disallow any access
  end

end
