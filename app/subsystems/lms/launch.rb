class Lms::Launch

  attr_reader :app, :message
  attr_reader :request_parameters

  class Error < StandardError; end
  class AppNotFound < Error; end
  class InvalidSignature < Error; end
  class AlreadyUsed < Error; end
  class CouldNotLoadLaunch < Error; end

  def self.from_request(request)
    new(request_parameters: request.request_parameters, request_url: request.url)
  end

  def persist!
    Lms::Models::ValidLaunchData.create!(
      request_params: request.request_parameters,
      request_url: request.url
    ).id
  end

  def self.from_id(id)
    launch_data = Lms::Models::ValidLaunchData.find(id)
    raise CouldNotLoadLaunch if launch_data.nil?
    launch = new(request_parameters: launch_data.request_parameters,
                 request_url: launch_data.request_url,
                 trusted: true)
    launch_data.destroy
    launch
  end

  def is_assignment?
    result_sourcedid.present? && outcome_url.present?
  end

  def result_sourcedid
    request_parameters[:lis_result_sourcedid]
  end

  def outcome_url
    request_parameters[:lis_outcome_service_url] ||
    request_parameters[:ext_ims_lis_basic_outcome_url]
  end

  def lms_user_id
    request_parameters[:user_id]
  end

  def full_name
    request_parameters[:lis_person_name_full]
  end

  def email
    request_parameters[:lis_person_contact_email_primary]
  end

  def role
    # Let's start with recognizing only definite instructor and student roles; there
    # are a zillion roles defined in LIS and JP thinks we should be aware of the roles
    # we are handling and which we consider to be instructors.

    @role ||= begin
      lms_roles = request_parameters[:roles].split(',')
      if lms_roles.any?{|lms_role| lms_role.match(/Instructor/)}
        :instructor
      elsif lms_roles.any?{|lms_role| lms_role.match(/Student|Learner/)}
        :student
      else
        :other
      end
    end
  end

  def is_student?
    :student == role
  end

  def is_instructor?
    :instructor == role
  end

  def app
    if @app.nil?
      @app = Lms::Models::App.find_by(key: request_parameters[:oauth_consumer_key])
      raise AppNotFound if @app.nil?
    end
    @app
  end

  protected

  def initialize(request_paramaters:, request_url:, trusted: false)
    @request_parameters = request.request_parameters

    if trusted
      @message = IMS::LTI::Models::Messages::Message.generate(request_parameters)
      @message.launch_url = request_url
    else
      begin
        Lms::Models::Nonce.create!({ lms_app_id: app.id, value: request_parameters[:oauth_nonce] })
      rescue ActiveRecord::RecordNotUnique => ee
        raise AlreadyUsed
      end

      authenticator = ::IMS::LTI::Services::MessageAuthenticator.new(
        request.url,
        request_parameters,
        app.secret
      )

      raise InvalidSignature if !authenticator.valid_signature?

      @message = authenticator.message
    end
  end

  public

  def formatted_data(split_categories: true, include_everything: false)
    data = ""

    if (split_categories)
      data +=
        "\nRequired params:\n" +
        message.required_params.ai(plain:true, ruby19_syntax: true, indent: 2) +

        "\nRecommended params:\n" +
        message.recommended_params.ai(plain:true, ruby19_syntax: true, indent: 2) +

        "\nOptional params:\n" +
        message.optional_params.ai(plain:true, ruby19_syntax: true, indent: 2) +

        "\nExt params:\n" +
        message.ext_params.ai(plain:true, ruby19_syntax: true, indent: 2) +

        "\nCustom params:\n" +
        message.custom_params.ai(plain:true, ruby19_syntax: true, indent: 2) +

        "\nDeprecated params:\n" +
        message.deprecated_params.ai(plain:true, ruby19_syntax: true, indent: 2) +

        "\nOther misc params not always in `message`:\n" +
        {
          result_sourcedid: result_sourcedid,
          outcome_url: outcome_url
        }.ai(
          plain:true, ruby19_syntax: true, indent: 2
        )
    end

    if (include_everything)
      data += "\nEverything:\n" + message.ai(plain:true, ruby19_syntax: true, indent: 2)
    end

    data
  end

end
