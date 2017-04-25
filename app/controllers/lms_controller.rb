class LmsController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:launch]

  def configuration
  end

  def launch
    # Check that the request specifies a valid tool consumer
debugger
    consumer = Lms::Models::ToolConsumer.find_by(key: params[:oauth_consumer_key])
    return redirect_to action: :launch_failed if consumer.nil?

    # Check that the message has the correct OAuth signature

    authenticator = ::IMS::LTI::Services::MessageAuthenticator.new(
      request.url,
      request.request_parameters,
      consumer.secret
    )
    return redirect_to action: :launch_failed if !authenticator.valid_signature?

    # Check that we haven't seen this nonce yet

    begin
      Lms::Models::Nonce.create!({ lms_tool_consumer_id: consumer.id, value: params['oauth_nonce'] })
    rescue ActiveRecord::RecordNotUnique => ee
      return redirect_to action: :launch_failed
    end

    # All checks passed, move along

    redirect_to lti_someplace_url
  end

  def someplace
  end

  def launch_failed; end

end
