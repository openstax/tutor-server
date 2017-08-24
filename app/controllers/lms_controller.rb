require 'net/http'
require 'uri'
require 'oauth'

class LmsController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:launch, :ci_launch]
  skip_before_filter :authenticate_user!, only: [:configuration, :launch, :ci_launch]

  before_filter :allow_embedding_in_iframe, only: [:launch, :ci_launch]
  before_filter :get_app, only: [:launch, :ci_launch]
  before_filter :get_launch_message, only: [:launch, :ci_launch]

  layout false

  def configuration
  end

  def launch
    lms_user = Lms::Models::User.where(lti_user_id: params['user_id']).first
    if lms_user.nil?
      forward_user_to_accounts and return
    end


    respond_to do |format|
      format.html
    end

    # sourcedid is only set if user is a student
    submit_random_grade(app) if params['lis_result_sourcedid']
  end

  def ci_launch
    # https://www.imsglobal.org/specs/lticiv1p0/specification-3

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

  def launch_failed; end

  protected

  def allow_embedding_in_iframe
    response.headers["X-FRAME-OPTIONS"] = 'ALLOWALL'
  end

  def get_app
    @app = Lms::Models::App.find_by(key: params[:oauth_consumer_key])
    redirect_to action: :launch_failed if @app.nil?
  end

  def get_launch_message
    # Check that the message has the correct OAuth signature

    authenticator = ::IMS::LTI::Services::MessageAuthenticator.new(
      request.url,
      request.request_parameters,
      @app.secret
    )

    return redirect_to action: :launch_failed if !authenticator.valid_signature?

    @launch_message = authenticator.message

    # Check that we haven't seen this nonce yet

    begin
      Lms::Models::Nonce.create!({ lms_app_id: @app.id, value: params['oauth_nonce'] })
    rescue ActiveRecord::RecordNotUnique => ee
      redirect_to action: :launch_failed
    end
  end

  def forward_user_to_accounts
    url = openstax_accounts.login_url
    # params must be normalized so they're deterministic for the signature
    qp = OAuth::Helper.normalize(lti_account_params)
    # loosely from SO:
    # http://stackoverflow.com/questions/4084979/ruby-way-to-generate-a-hmac-sha1-signature-for-oauth
    secret_key = Rails.application.secrets.openstax['accounts']['secret']
    signature = OpenSSL::HMAC.hexdigest('sha1',secret_key, qp)

    redirect_to "#{url}?#{qp}&signature=#{signature}"
  end

  def lti_account_params
    {
      go: 'trusted_launch',
      timestamp: Time.now.to_i,
      uuid:  params[:user_id],
      name:  params[:lis_person_name_full],
      email: params[:lis_person_contact_email_primary],
      role:  params[:roles].split(',').include?('Instructor') ? :instructor : :student
    }
  end  
  
  def submit_random_grade(app)
    score = sprintf('%0.2f', rand)
    Rails.logger.debug "SET SCORE TO #{score}"

    Thread.abort_on_exception=true
    Thread.new {
      sleep 1
      auth = OAuth::Consumer.new(app.key, app.secret)
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
