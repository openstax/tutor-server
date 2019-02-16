require 'active_support/core_ext/module/delegation'

class Lms::Launch

  # A PORO that hides the details of a launch request's internals and
  # launch-related models from other LMS code.

  attr_reader :message
  attr_reader :request_parameters, :request_url

  class HandledError          < StandardError; end
  class InvalidSignature      < HandledError; end
  class AlreadyUsed           < HandledError; end
  class CourseScoreInUse      < HandledError; end
  class CourseKeysAlreadyUsed < HandledError; end
  class LmsDisabled           < HandledError; end

  class UnhandledError        < StandardError; end
  class AppNotFound           < UnhandledError; end
  class CouldNotLoadLaunch    < UnhandledError; end

  delegate :tool_consumer_instance_guid, :context_id, to: :message

  REQUIRED_FIELDS = [
    :tool_consumer_instance_guid,
    :context_id
  ]

  def self.from_request(request, authenticator: nil)
    new(
      request_parameters: request.request_parameters,
      request_url: request.url,
      authenticator: authenticator
    )
  end

  def persist!
    self.context || raise("context failed")
    Lms::Models::TrustedLaunchData.create!(
      request_params: request_parameters,
      request_url: request_url
    ).id
  end

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
    if @app.nil?
      [Lms::WilloLabs, Lms::Models::App].each do |model|
        @app = model.find_by(key: request_parameters[:oauth_consumer_key])
        return @app if @app
      end
      raise AppNotFound
    end
    @app
  end

  def tool_consumer!
    @tool_consumer ||= Lms::Models::ToolConsumer.find_or_create_by!(guid: tool_consumer_instance_guid)
  end

  def missing_required_fields
    @missing_required_fields ||= REQUIRED_FIELDS.select do |required_field|
      send(required_field).blank?
    end
  end

  def context
    @context ||= (find_existing_context || create_context!)
  end

  def find_existing_context
    query = Lms::Models::Context.eager_load(:course).where(lti_id: context_id)

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
    raise LmsDisabled if course && !course.is_lms_enabled

    # In theory, we could allow multiple LTI context IDs to point to the same Tutor course (e.g. if
    # one teacher has 3 sections and uses 3 LMS courses to point to one Tutor course).  For this reason
    # we don't currently prohibit this with a database constraint.  But for the time being, we do
    # restrict this here in code by requiring, in the auto create call, that a course only be used
    # in one Context.

    raise CourseKeysAlreadyUsed if course && Lms::Models::Context.where(course: course).exists?

    Lms::Models::Context.create!(
      lti_id: context_id,
      tool_consumer: tool_consumer!,
      course: course
    )
  end

  def update_tool_consumer_metadata!
    # TODO use the data in the launch to update what we know about the tool consumer
    # includes admin email addresses, LMS version, etc.
  end

  def store_score_callback(user)
    # For assignment launches, store the score passback info.  We are currently
    # only doing course-level score sync, so store the score callback info on the Student
    # record. Since we may not actually have a Student record yet (if enrollment hasn't completed),
    # we really attach it to the combination of course and user (which is essentially what
    # a Student later records).  It is possible that a teacher could add the Tutor assignment
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
        profile: user.to_model,
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
        profile: user.to_model
      )
    end
  end

  protected

  def initialize(request_parameters:, request_url:, trusted: false, authenticator: nil)
    @request_parameters = request_parameters
    @request_url = request_url

    # ims-lti gem gives a lot of "unknown parameter" warnings even for params
    # that Canvas commonly sends; silence those except in dev env

    if trusted
      with_warnings(warning_verbosity) do
        @message = IMS::LTI::Models::Messages::Message.generate(request_parameters)
        @message.launch_url = request_url
      end
    else
      begin
        Lms::Models::Nonce.create!({ lms_app_id: app.id, value: request_parameters[:oauth_nonce] })
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => ee
        Raven.capture_message("Attempt to reuse nonce #{request_parameters[:oauth_nonce]} on app id #{app.id}")
        raise AlreadyUsed
      end

      with_warnings(warning_verbosity) do
        authenticator = authenticator || ::IMS::LTI::Services::MessageAuthenticator.new(
          request_url,
          request_parameters,
          app.secret
        )
        raise InvalidSignature if !authenticator.valid_signature?
        @message = authenticator.message
      end
    end
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
