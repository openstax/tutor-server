require 'net/http'
require 'uri'
require 'oauth'

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

    # sourcedid is only set if user is a student
    submit_random_grade(consumer) if params['lis_result_sourcedid']
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

  protected

  def submit_random_grade(consumer)
    score = sprintf('%0.2f', rand)
    Rails.logger.debug "SET SCORE TO #{score}"

    Thread.abort_on_exception=true
    Thread.new {
      sleep 1
      auth = OAuth::Consumer.new(consumer.key, consumer.secret)
      token = OAuth::AccessToken.new(auth)
      xml = render_to_string(
        template: 'lms/random_outcome.xml',
        locals: {
          :@score => score,
          :@source_id => params['lis_result_sourcedid']
        }
      )
      response = token.post(
        params['lis_outcome_service_url'], xml, {'Content-Type' => 'application/xml'}
      )
      Rails.logger.debug response.body
    }
  end
end
