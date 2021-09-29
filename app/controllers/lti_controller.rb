class LtiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :callback # handled by Omniauth
  # login happens immediately after callback
  # jwks is a public key for the LTI platform
  skip_before_action :authenticate_user!, only: [ :callback, :jwks ]

  layout false

  # LTI context roles allowed to pair courses and become instructors
  INSTRUCTOR_ROLES = [ 'Instructor', 'Administrator', 'ContentDeveloper', 'Mentor' ]

  # LTI context roles allowed to enroll into courses as students
  STUDENT_ROLES = [ 'Learner' ]

  helper_method :is_definitely_student?

  # This endpoint is reached after the OpenID Connect login (handled by omniauth_openid_connect)
  # Send to accounts for login, then back to launch endpoint
  # Associate the logged-in user with the LTI info saved in the session
  # Instructors are redirected to the pair page or added to the course
  # Students are enrolled into the course
  # Users are redirected to the target_link_uri afterwards unless that would cause a loop
  # This is equivalent to launch_authenticate in the old LmsController
  def callback
    # The result of the successful omniauth authentication is stored in request.env
    lti_auth = request.env['omniauth.auth']

    raw_info = lti_auth.extra.raw_info
    roles = raw_info['https://purl.imsglobal.org/spec/lti/claim/roles']
    return render_failure(:missing_roles) if roles.nil?

    context_roles ||= roles.select do |role|
      role.starts_with? 'http://purl.imsglobal.org/vocab/lis/v2/membership#'
    end.map { |role| role.sub('http://purl.imsglobal.org/vocab/lis/v2/membership#', '') }

    # These are used in error messages so we try to set them as early as possible
    session['lti_is_instructor'] = !(INSTRUCTOR_ROLES & context_roles).empty?
    session['lti_is_student'] = !(STUDENT_ROLES & context_roles).empty?

    return render_failure(:unsupported_message_type) unless raw_info[
      'https://purl.imsglobal.org/spec/lti/claim/message_type'
    ] == 'LtiResourceLinkRequest'

    session['lti_uid'] = lti_auth.uid

    # Fail for anonymous launches since we need to pass back grades
    # and anonymous launches do not give us a user ID
    return render_failure(:anonymous_launch) if session['lti_uid'].blank?

    session['lti_context_id'] = raw_info[
      'https://purl.imsglobal.org/spec/lti/claim/context'
    ]&.[]('id')
    return render_failure(:missing_context) if session['lti_context_id'].blank?

    return render_failure(:no_valid_roles) \
      unless session['lti_is_instructor'] || session['lti_is_student']

    session['lti_target_link_uri'] = raw_info[
      'https://purl.imsglobal.org/spec/lti/claim/target_link_uri'
    ]
    return render_failure(:missing_target_link_uri) if session['lti_target_link_uri'].blank?

    # Possible errors:
    # :missing_context
    # :missing_resource_link
    # :missing_endpoint
    # :missing_scope
    error = Lti::ResourceLink.upsert_from_platform_and_raw_info lti_platform, raw_info

    # We allow users to proceed when the endpoint is missing so they can login to Tutor via the LMS,
    # even if Tutor is then not allowed to update the LMS's gradebook
    return render_failure(error) unless error.nil? || error == :missing_endpoint

    # Existing user, already linked to the LMS, not signed in or signed into the wrong account
    # Force the user to sign in to the account linked to the Lti::User
    # If we wanted to be extra careful, we could fail with an error instead
    # if they are signed in to the wrong account
    sign_in(lti_user.profile) if !lti_user.profile.nil? && current_user != lti_user.profile

    # Proceed with the launch (will redirect to Accounts instead if they are not signed in yet)
    # TODO: Use Accounts signed params or the FindOrCreateAccount routine to automatically
    #       create the account with pre-filled fields and force the user to login to it
    redirect_to lti_launch_url
  end

  # This endpoint is reached when coming back from Accounts after logging in after an LTI launch
  # The LTI user is paired with the account, if needed
  # Instructors are redirected to the pair page or added to the course
  # Students are enrolled into the course
  # Users are redirected to the target_link_uri afterwards unless that would cause a loop
  # This is equivalent to complete_launch in the old LmsController
  def launch
    # Fail if we couldn't find the LTI session
    # This can happen if cookies are being blocked
    # or if they try to load this URL directly without going through LTI (misconfigured LMS?)
    return render_failure(:missing_session) if session['lti_guid'].blank?

    # TODO: Display a confirmation modal before linking the account to the LMS and/or
    #       Prevent one profile from being linked to multiple Lti::User in a single platform
    #       The second option may cause issues with student view in Canvas,
    #       as the student view seems to show up as a separate user for Tutor
    if lti_user.profile.nil?
      lti_user.profile = current_user
      return render_failure(:account_already_paired) unless lti_user.save
    end

    # Fail if we got this far and the user is still in the wrong account
    # This can happen due to multiple tabs, shared accounts
    # or trying to reload this URL after switching accounts
    return render_failure(:wrong_account) if lti_user.profile != current_user

    if lti_context.course.nil?
      # No course is currently paired with the LMS course
      if session['lti_is_instructor'] && CourseMembership::Models::Teacher.joins(:role).where(
        deleted_at: nil, role: { profile: current_user }
      ).exists?
        # This user is allowed to pair courses and has courses to pair
        # Render screen to let them pick a course
        render :pair
      else
        # This user is not allowed to pair courses or has no courses to pair
        render_failure :unpaired
      end

      return
    end

    course = lti_context.course
    if session['lti_is_instructor']
      # This user is allowed to join the course as an instructor
      # We don't really block them here if the course has ended,
      # maybe they need to look at the scores or something like that

      # Another instructor launches the same course after initial pairing
      # Add them as an instructor for the Tutor course
      AddUserAsCourseTeacher[user: current_user, course: course] \
        unless UserIsCourseTeacher[user: current_user, course: course] ||
               UserIsCourseStudent[user: current_user, course: course]
    elsif session['lti_is_student']
      # This user is allowed to join the course as a student
      # We skip this part if the user is an instructor
      # because we do not allow instructors to also join the same course as a student in Tutor

      # Instructor needs to pair the course first so we know
      # which course corresponds to the given context ID
      return render_failure(:unpaired) if course.nil?

      unless UserIsCourseTeacher[user: current_user, course: course] ||
             UserIsCourseStudent[user: current_user, course: course, include_dropped_students: true]
        # Enroll into the course
        # The enrollment process will block them if the course already ended
        redirect_to token_enroll_url(course.uuid), return_to: target_link_uri(course)
        clear_lti_session
        return
      end
    end

    redirect_to target_link_uri(course)
    clear_lti_session
  end

  def pair
    course = CourseProfile::Models::Course.find_by! id: params[:course_id]
    OSU::AccessPolicy.require_action_allowed! :lti_pair, current_user, course

    # The lti_context in the session is already paired to an OpenStax Tutor course
    return render_failure(:context_already_paired) unless lti_context.course.nil?

    # TODO: fail with course_already_paired if the selected course is paired
    #       to a different lti_context in the same lti_platform?
    #       Or let them unpair the Tutor course and pair again

    # Can't pair a course that has already ended
    return render_failure(:course_ended) if course.ended?

    # TODO: Fail or at least display a warning if the course has non-LMS students
    # (is_lms_enabling_allowed == false)

    lti_context.update_attribute :course, course
    course.update_attribute :is_lms_enabled, true

    # Continue with the launch
    redirect_to lti_launch_url
  end

  def jwks
    jwk = OpenSSL::PKey::RSA.new(Rails.application.secrets.lti[:private_key]).public_key.to_jwk
    render json: { keys: [ jwk ] }
  end

  protected

  # If this returns true, we display simplified error messages,
  # usually something like "contact your instructor".
  def is_definitely_student?
    session['lti_is_student'] && !session['lti_is_instructor']
  end

  def lti_platform
    # The platform comes from a tutor_guid parameter we add to the first Tutor URL
    # the user is sent to from the LMS (in Omniauth's request_phase)
    # That parameter is saved in the session so we can find the platform in the callback_phase
    # We do this to get around the fact that all Canvas deployments shared the same LTI Issuer,
    # so we couldn't distinguish them and determine which configuration/keys to use otherwise
    # Omniauth handles missing platform and other errors in the callback_phase before this point
    @lti_platform ||= Lti::Platform.find_by! guid: session['lti_guid']
  end

  def lti_user
    @lti_user ||= Lti::User.find_or_initialize_by platform: lti_platform, uid: session['lti_uid']
  end

  def lti_context
    @lti_context ||= Lti::Context.find_or_initialize_by(
      platform: lti_platform, context_id: session['lti_context_id']
    )
  end

  def target_link_uri(course)
    uri = session['lti_target_link_uri']
    path = Addressable::URI.parse(uri).path
    path.starts_with?('/lms/') || path.starts_with?('/lti/') ? course_dashboard_url(course) : uri
  end

  def clear_lti_session
    session.delete 'lti_guid'
    session.delete 'lti_uid'
    session.delete 'lti_context_id'
    session.delete 'lti_is_instructor'
    session.delete 'lti_is_student'
    session.delete 'lti_target_link_uri'
  end

  def render_failure(name)
    render "lti/failures/#{name}", layout: 'minimal_error'
    clear_lti_session
  end
end
