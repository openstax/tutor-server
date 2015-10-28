class AuthController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :status

  VALID_CALLBACK_PATTERN = /^[a-zA-Z0-9\._]+$/

  def status
    render :not_acceptable and return unless valid_jsonp_request?

    body = strategy.authorize.body.slice('access_token')
    body[:current_user] = if current_user.is_anonymous?
                            false
                          else
                            Api::V1::UserRepresenter.new(current_user)
                          end

    respond_to do |format|
      format.js do
        render json: body, callback: '/**/' + params[:callback]
      end
    end

  end


  private

  # Checks if the callback function name is safe/valid.
  # There's a SWF based attack vector that uses jsonp callbacks
  # https://miki.it/blog/2014/7/8/abusing-jsonp-with-rosetta-flash/
  def valid_jsonp_request?
    params[:callback] && params[:callback].match(VALID_CALLBACK_PATTERN)
  end

  def strategy
    @strategy ||= server.token_request params[:grant_type]
  end

  def authorize_response
    @authorize_response ||= strategy.authorize
  end

  def server
    @server ||= Doorkeeper::Server.new(self)
  end

end
