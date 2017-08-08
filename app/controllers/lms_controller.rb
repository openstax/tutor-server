class LmsController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:launch, :ci_launch]
  skip_before_filter :authenticate_user!, only: [:configuration, :launch, :ci_launch]

  layout false

  def configuration
  end

  def launch
    response.headers["X-FRAME-OPTIONS"] = 'ALLOWALL'

    # Check that the request specifies a valid tool consumer
    consumer = Lms::Models::ToolConsumer.find_by(key: params[:oauth_consumer_key])
    return redirect_to action: :launch_failed if consumer.nil?

    # Check that the message has the correct OAuth signature

    authenticator = ::IMS::LTI::Services::MessageAuthenticator.new(
      request.url,
      request.request_parameters,
      consumer.secret
    )
    return redirect_to action: :launch_failed if !authenticator.valid_signature?

    @launch_message = authenticator.message
    # Check that we haven't seen this nonce yet

    # begin
    #   Lms::Models::Nonce.create!({ lms_tool_consumer_id: consumer.id, value: params['oauth_nonce'] })
    # rescue ActiveRecord::RecordNotUnique => ee
    #   return redirect_to action: :launch_failed
    # end

    # All checks passed, move along

    respond_to do |format|
      format.html
    end
  end

  def ci_launch
    # https://www.imsglobal.org/specs/lticiv1p0/specification-3

    # Allow embedding in Canvas iframe
    response.headers["X-FRAME-OPTIONS"] = 'ALLOWALL'

    consumer = Lms::Models::ToolConsumer.find_by(key: params[:oauth_consumer_key])
    return redirect_to action: :launch_failed if consumer.nil?

    authenticator = ::IMS::LTI::Services::MessageAuthenticator.new(
      request.url,
      request.request_parameters,
      consumer.secret
    )
    return redirect_to action: :launch_failed if !authenticator.valid_signature?

    @launch_message = authenticator.message

    @cis = IMS::LTI::Models::Messages::ContentItemSelection.new(
      content_items: [
        IMS::LTI::Models::ContentItems::LtiLinkItem.new(
          media_type: 'application/vnd.ims.lti.v1.ltilink',
          text: 'A URL to click',
          url: lms_launch_url,
          thumbnail: IMS::LTI::Models::Image.new(id: 'test', height: 123, width: 456)
        )
      ]
    )
  end

  def someplace
  end

  def launch_failed; end

end
