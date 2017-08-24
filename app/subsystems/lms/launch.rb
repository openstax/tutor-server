class Lms::Launch

  attr_reader :app, :message

  class LmsLaunchError < StandardError; end
  class AppNotFound < LmsLaunchError; end
  class InvalidSignature < LmsLaunchError; end
  class AlreadyUsed < LmsLaunchError; end

  def initialize(app_key:, request_url:, request_params:, nonce:)
    @app = Lms::Models::App.find_by(key: app_key)
    raise AppNotFound if @app.nil?

    authenticator = ::IMS::LTI::Services::MessageAuthenticator.new(
      request.url,
      request.request_parameters,
      @app.secret
    )

    raise InvalidSignature if !authenticator.valid_signature?

    @message = authenticator.message

    begin
      Lms::Models::Nonce.create!({ lms_app_id: @app.id, value: nonce })
    rescue ActiveRecord::RecordNotUnique => ee
      raise AlreadyUsed
    end
  end

end
