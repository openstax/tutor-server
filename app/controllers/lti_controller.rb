class LtiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :callback # This is handled by Omniauth
  skip_before_action :authenticate_user!, only: :callback # Login happens right after this step

  layout false

  # Any of these LTI context roles are allowed to pair courses and become teachers
  COURSE_ADMIN_ROLES = [ 'Instructor', 'Administrator', 'ContentDeveloper', 'Mentor' ]

  helper_method :lti_user

  # This endpoint is reached after the OpenID Connect login (handled by omniauth_openid_connect)
  # Send to accounts for login, then back to launch endpoint
  # Associate the logged-in user with the LTI info saved in the session
  # Instructors are redirected to the pair page or added to the course
  # Students are enrolled into the course
  # Users are redirected to the target_link_uri afterwards unless that would cause a loop
  # This is equivalent to launch_authenticate in the old LmsController
  def callback
    # The platform comes from a tutor_guid parameter we add to the first Tutor URL
    # the user is sent to from the LMS (in Omniauth's request_phase)
    # That parameter is saved in the session so we can find the platform in the callback_phase
    # We do this to get around the fact that all Canvas deployments shared the same LTI Issuer,
    # so we couldn't distinguish them and determine which configuration/keys to use otherwise
    # Omniauth handles missing platform and other errors in the callback_phase before this point
    # We no longer need or use the saved lti_guid parameter after this point
    # since it'll be loaded from the Lti::User
    platform = Lti::Platform.find_by! guid: session.delete('lti_guid')

    # The result of the successful omniauth authentication is stored in request.env
    lti_auth = request.env['omniauth.auth']
    uid = lti_auth.uid

    # Find or create a new LTI user and store the current launch info in it
    # We do this before asking them to login so we don't have to store their auth info elsewhere
    # Storing the auth info in the session leads to CookieOverflow exceptions
    @lti_user = Lti::User.find_or_initialize_by(platform: platform, uid: uid)

    # Possible errors:
    # :anonymous_launch
    # :unsupported_message_type
    # :missing_context
    # :missing_roles
    # :no_valid_roles
    # :missing_target_link_uri
    error = lti_user.set_launch_info_from_lti_auth lti_auth
    return render_failure(error) unless error.nil?

    lti_user.save!

    # Save the LTI user info so we can resume the process once they come back
    # from Accounts or from pairing a course
    session['lti_user_id'] = lti_user.id

    # Existing user, already linked to the LMS, not signed in or signed into the wrong account
    # Force the user to sign in to the account linked to the Lti::User
    # If we wanted to be extra careful, we could fail with an error instead
    # if they are signed in to the wrong account
    sign_in(lti_user.profile) if !lti_user.profile.nil? && current_user != lti_user.profile

    # Proceed with the launch (will redirect to Accounts instead if they are not signed in yet)
    redirect_to lti_launch_url
  end

  # This endpoint is reached when coming back from Accounts after logging in after an LTI launch
  # The LTI user is paired with the account, if needed
  # Instructors are redirected to the pair page or added to the course
  # Students are enrolled into the course
  # Users are redirected to the target_link_uri afterwards unless that would cause a loop
  # This is equivalent to complete_launch in the old LmsController
  def launch
    # Fail if we couldn't find the lti_user object
    # This can happen if cookies are being blocked
    # or if they try to load this URL directly without going through LTI (misconfigured LMS?)
    return render_failure(:missing_session) if lti_user.nil?

    # In the future we may support other messages such as LtiDeepLinkingRequest
    # However, this controller action only handles LtiResourceLinkRequests
    return render_failure(:unsupported_message_type) \
      unless lti_user.last_message_type == 'LtiResourceLinkRequest'

    # TODO: Display a confirmation modal before linking the account to the LMS?
    lti_user.update_attribute(:profile, current_user) if lti_user.profile.nil?

    # Fail if we got this far and the user is still in the wrong account
    # This can happen due to multiple tabs, shared accounts
    # or trying to reload this URL after switching accounts
    return render_failure(:wrong_account) if lti_user.profile != current_user

    # Find the course by the platform and the LTI context's id
    course = CourseProfile::Models::Course.joins(:lti_contexts).find_by(
      lti_contexts: { platform: lti_user.platform, context_id: lti_user.last_context_id }
    )

    if course.nil?
      # No course is currently paired with the LMS course
      if lti_user.last_is_instructor? && CourseMembership::Models::Teacher.joins(:role).where(
        deleted_at: nil, role: { profile: current_user }
      ).exists?
        # This user is allowed to pair courses and has courses to pair
        # Render screen to let them pick a course
        return render :pair
      end

      # This user is not allowed to pair courses or has no courses to pair
      return render_failure(:unpaired)
    end

    if lti_user.last_is_instructor?
      # This user is allowed to join the course as an instructor
      # We don't really block them here if the course has ended,
      # maybe they need to look at the scores or something like that

      # Another instructor launches the same course after initial pairing
      # Add them as an instructor for the Tutor course
      AddUserAsCourseTeacher[user: current_user, course: course] \
        unless UserIsCourseTeacher[user: current_user, course: course]
    elsif lti_user.last_is_student?
      # This user is allowed to join the course as a student
      # We skip this part if the user is an instructor
      # because we do not allow instructors to also join the same course as a student in Tutor

      # Instructor needs to pair the course first so we know
      # which course corresponds to the given context ID
      return render_failure(:unpaired) if course.nil?

      unless UserIsCourseStudent[course: course, user: current_user, include_dropped_students: true]
        # Enroll into the course
        # The enrollment process will block them if the course already ended
        redirect_to token_enroll_url(course.uuid), return_to: target_link_uri
        clear_lti_session
        return
      end
    end

    redirect_to target_link_uri
    clear_lti_session
  end

  def pair
    course = CourseProfile::Models::Course.find_by! id: params[:course_id]
    OSU::AccessPolicy.require_action_allowed! :lms_course_pair, current_user, course

    # Can't pair a course that has already ended
    return render_failure(:course_ended) if course.ended?

    lti_user = Lti::User.find session['lti_user_id']
    Lti::Context.create!(
      platform: lti_user.platform, context_id: lti_user.last_context_id, course: course
    )

    # Continue with the launch
    redirect_to lti_launch_url
  end

  protected

  def lti_user
    @lti_user ||= Lti::User.find_by id: session['lti_user_id']
  end

  def target_link_uri
    uri = lti_user.last_target_link_uri
    path = Addressable::URI.parse(uri).path
    path.starts_with?('/lms/') || path.starts_with?('/lti/') ? course_dashboard_url(course) : uri
  end

  def clear_lti_session
    session.delete 'lti_guid'
    session.delete 'lti_user_id'
  end

  def render_failure(name)
    render "lti/failures/#{name}", layout: 'minimal_error'
    clear_lti_session
  end
end
