require 'active_support/core_ext/module/delegation'

class Lms::Launch
  # A PORO that hides the details of a launch request's internals and
  # launch-related models from other LMS code.

  attr_reader :authenticator, :message, :request_parameters, :request_url, :trusted

  class HandledError          < StandardError; end
  class LmsDisabled           < HandledError; end
  class CourseEnded           < HandledError; end
  class InvalidSignature      < HandledError; end
  class ExpiredTimestamp      < HandledError; end
  class InvalidTimestamp      < HandledError; end
  class NonceAlreadyUsed      < HandledError; end
  class CourseScoreInUse      < HandledError; end

  class UnhandledError        < StandardError; end
  class AppNotFound           < UnhandledError; end
  class CouldNotLoadLaunch    < UnhandledError; end

  delegate :tool_consumer_instance_guid, :context_id, to: :message

  MAX_REQUEST_AGE = 5.minutes
  REQUIRED_FIELDS = [
    :tool_consumer_instance_guid,
    :context_id
  ]

  redis_secrets = Rails.application.secrets.redis
  # STORE needs to be an ActiveSupport::Cache::RedisStore to support TTL
  STORE = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets[:url],
    namespace: redis_secrets[:namespaces][:lms],
    expires_in: 2 * MAX_REQUEST_AGE # 2x Just in case their clocks are far in the future
  )

  # You MUST call validate! immediately after this method
  # This is not done automatically in order to enable better error handling
  def self.from_request(request, authenticator: nil)
    new(
      request_parameters: request.request_parameters,
      request_url: request.url,
      authenticator: authenticator
    )
  end

  def persist!
    context
    Lms::Models::TrustedLaunchData.create!(
      request_params: request_parameters,
      request_url: request_url
    ).id
  end

  # You MUST call validate! immediately after this method
  # This is not done automatically in order to enable better error handling
  def self.from_id(id)
    launch_data = Lms::Models::TrustedLaunchData.find_by(id: id)
    raise CouldNotLoadLaunch if launch_data.nil?
    new(request_parameters: ActiveSupport::HashWithIndifferentAccess.new(launch_data.request_params),
        request_url: launch_data.request_url,
        trusted: true)
  end

  def is_assignment?
    result_sourcedid.present? && outcome_url.present?
  end

  def result_sourcedid
    request_parameters[:lis_result_sourcedid]
  end

  def resource_link_id
    request_parameters[:resource_link_id]
  end

  def outcome_url
    request_parameters[:lis_outcome_service_url] ||
    request_parameters[:ext_ims_lis_basic_outcome_url]
  end

  def lms_user_id
    request_parameters[:user_id]
  end

  def lms_tc_scoped_user_id
    "#{lms_user_id}--#{tool_consumer_instance_guid}"
  end

  def full_name
    request_parameters[:lis_person_name_full]
  end

  def email
    request_parameters[:lis_person_contact_email_primary]
  end

  def school
    request_parameters[:tool_consumer_instance_name]
  end

  def role
      # We start with recognizing only the roles that we can logically map to
      # either an instructor or student
      # There are a zillion other roles that we don't support
      # The accounts service does support other types of accounts such as
      # "Administrator", "Adjunct", and "Librarian", but we only send
      # "instructor" or "student" because that's what we need returned in order
      # for Tutor to setup the user with the proper access
      @role ||= begin
        lms_roles = (request_parameters[:roles] || '').split(',')
        if lms_roles.any?{|lms_role| lms_role.match(/Instructor|Creator|Faculty|Mentor|Staff|Support|Admin/)}
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
    return @app if @app.present?
    @app = Lms::Queries.app_for_key(request_parameters[:oauth_consumer_key])
    raise AppNotFound unless @app.present?
    @app
  end

  def find_or_create_tool_consumer!
    @tool_consumer ||= Lms::Models::ToolConsumer.find_or_create_by!(
      guid: tool_consumer_instance_guid
    )
  end

  def missing_required_fields
    @missing_required_fields ||= REQUIRED_FIELDS.select do |required_field|
      send(required_field).blank?
    end
  end

  def context
    @context ||= find_existing_context || create_context!
  end

  def find_existing_context
    query = Lms::Models::Context.eager_load(:course)
              .where(lti_id: context_id)

    # occasionally a LMS will re-use a context from one course
    # to another even if the LMS course's keys have changed
    # To prevent that we also filter by the Tutor course
    if app.owner.is_a? CourseProfile::Models::Course
      query = query.where(course: app.owner)
    end
    
    if @tool_consumer.nil?
      query = query.joins(:tool_consumer)
                .where(tool_consumer: { guid: tool_consumer_instance_guid })
    else
      query = query.where(tool_consumer: @tool_consumer)
    end

    query.first
  end

  def create_context!
    course = app.owner
    # nil course means unpaired WilloLabs course so we allow it
    unless course.nil?
      raise CourseEnded if course.ended?
      raise LmsDisabled unless course.is_lms_enabled
    end

    Lms::Models::Context.create!(
      lti_id: context_id,
      tool_consumer: find_or_create_tool_consumer!,
      app_type: app.class,
      course: course
    )
  end

  def update_tool_consumer_metadata!
    # TODO use the data in the launch to update what we know about the tool consumer
    # includes admin email addresses, LMS version, etc.
  end

  def store_score_callback(user)
    # For assignment launches, store the score passback info. We are currently
    # only doing course-level score sync, so store the score callback info on the Student
    # record. Since we may not actually have a Student record yet (if enrollment hasn't completed),
    # we really attach it to the combination of course and user (which is essentially what
    # a Student later records). It is possible that a teacher could add the Tutor assignment
    # more than once, so we could have multiple callback infos for ever course/user combination.
    # Also, per the LTI implementation guide, we should only keep one sourcedid for every
    # resource_link_id and user combination, so clear old ones before saving the new one.

    return if !is_assignment?

    Lms::Models::CourseScoreCallback.transaction do
      # per https://www.imsglobal.org/specs/ltiv1p1p1/implementation-guide
      # resource_link_id corresponds to a link to the assignment
      # lis_result_sourcedid is LIS Result Identifier associated with the
      # launch and identifies a unique row and column within the gradebook.
      # only the most recent resource_link_id should be retained
      Lms::Models::CourseScoreCallback.where(
        course: context.course,
        profile: user,
        resource_link_id: resource_link_id
      ).destroy_all

      # remove any duplicated callbacks
      Lms::Models::CourseScoreCallback.where(
        result_sourcedid: result_sourcedid,
        outcome_url: outcome_url
      ).each do |csc|
        # if the profile for the duplicate CourseScoreCallback was
        # abandoned then it's safe to destroy it
        # But something is broken if the profile has joined a course
        if UserIsCourseStudent[course: csc.course, user: csc.profile]
          raise CourseScoreInUse
        else
          csc.destroy!
        end
      end

      Lms::Models::CourseScoreCallback.create!(
        resource_link_id: resource_link_id,
        result_sourcedid: result_sourcedid,
        outcome_url: outcome_url,
        course: context.course,
        profile: user
      )
    end
  end

  def validate!
    # ims-lti gem gives a lot of "unknown parameter" warnings even for params
    # that Canvas commonly sends; silence those except in dev env
    if trusted
      with_warnings(warning_verbosity) do
        @message = IMS::LTI::Models::Messages::Message.generate(request_parameters)
        @message.launch_url = request_url
      end
    else
      # OAuth 1.0a checks
      with_warnings(warning_verbosity) do
        @authenticator ||= ::IMS::LTI::Services::MessageAuthenticator.new(
          request_url,
          request_parameters,
          app.secret
        )

        # Check that the request has a valid signature
        raise InvalidSignature unless authenticator.valid_signature?

        # Check that the request is not too old
        current_time = Time.current
        timestamp = Time.at(request_parameters[:oauth_timestamp].to_i)
        raise ExpiredTimestamp if current_time - timestamp > MAX_REQUEST_AGE

        # Check that the LMS's clock is not too far into the future
        raise InvalidTimestamp if timestamp - current_time > MAX_REQUEST_AGE

        key = "#{app.id}/#{timestamp}/#{request_parameters[:oauth_nonce]}"

        # Check that we haven't seen the same app/timestamp/nonce combo recently
        raise NonceAlreadyUsed if STORE.exist?(key)

        # Store the nonce in Redis (TTL is set in the store definition above)
        STORE.write key, 't'

        @message = authenticator.message
      end
    end

    self
  end

  protected

  def initialize(request_parameters:, request_url:, trusted: false, authenticator: nil)
    @request_parameters = request_parameters
    @request_url = request_url
    @trusted = trusted
    @authenticator = authenticator
  end

  def warning_verbosity
    Rails.env.development? ? $VERBOSE : nil
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

        "\nUnknown params:\n" +
        message.unknown_params.ai(plain:true, ruby19_syntax: true, indent: 2) +

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
