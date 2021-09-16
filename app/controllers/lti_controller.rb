class LtiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :callback # This is handled by Omniauth
  skip_before_action :authenticate_user!, only: :callback # Login happens right after this step

  layout false

  # Any of these LTI context roles are allowed to pair courses and become teachers
  COURSE_ADMIN_ROLES = [ 'Instructor', 'Administrator', 'ContentDeveloper', 'Mentor' ]

  # This endpoint is reached after the OpenID Connect login (handled by omniauth_openid_connect)
  # Send to accounts for login, then back to launch endpoint
  # Associate the logged-in user with the LTI info saved in the session
  # Instructors are redirected to the pair page or added to the course
  # Students are enrolled into the course
  # Users are redirected to the target_link_uri afterwards unless that would cause a loop
  # This is equivalent to launch_authenticate in the old LmsController
  def callback
    # Fail for anonymous launches since we need to pass back grades
    # and anonymous launches do not give us a user ID
    return render_failure(:anonymous_launch_not_supported) if uid.nil?

    if lti_user.nil?
      # New LMS user
      if current_user.is_anonymous?
        # Save the LTI auth info so we can resume the process once they come back from Accounts
        session['lti_auth'] = lti_auth

        # Send them to accounts to either create a new OpenStax account or login to an existing one
        return redirect_to openstax_accounts.login_url(return_to: lti_launch_url)
      else
        # Create an LTI User object to identify the current user and let them login via the LMS
        # TODO: Display a confirmation modal before linking the account?
        Lti::User.create! platform: platform, uid: uid, profile: current_user
      end
    else
      # Existing LMS user

      # Not signed into Tutor or signed into the wrong account
      # Force them to sign in to the account linked to the Lti::User
      # If they are signed in to the wrong account we could fail with an error instead
      # (only if we wanted to be extra careful)
      sign_in!(lti_user.profile) if current_user != lti_user.profile
    end

    # The user is now signed in to the correct account, so proceed with the launch
    launch
  end

  # This endpoint is reached when coming back from Accounts after logging in after an LTI launch
  # The code is also called within #callback if already logged in or automatically logged in
  # Instructors are redirected to the pair page or added to the course
  # Students are enrolled into the course
  # Users are redirected to the target_link_uri afterwards unless that would cause a loop
  # This is equivalent to complete_launch in the old LmsController
  def launch
    # Fail if we got this far and the user is still in the wrong account
    # This can happen due to multiple tabs or shared account shenanigans in the previous step
    return render_failure(:wrong_account) if lti_user != current_user

    # Find the course by the platform and the LTI context's id
    if course_admin?
      if course.nil?
        # No course is currently paired with the LMS course
        if CourseMembership::Models::Teacher.joins(:role).where(
          deleted_at: nil, role: { profile: current_user }
        ).exists? || current_user.account.confirmed_faculty?
          # Save the LTI auth info so we can resume the process once they come back from pairing
          session['lti_auth'] = lti_auth

          # Let them pick a course to pair or create a new one
          return render :pair
        else
          # No courses to pair and cannot create new courses
          return render_failure(:no_courses)
        end
      end

      # Another instructor launches the same course after initial pairing
      # Add them as an instructor for the Tutor course
      AddUserAsCourseTeacher[user: current_user, course: course] \
        unless UserIsCourseTeacher[user: current_user, course: course]
    end

    if student?
      # Instructor needs to pair the course first so we know
      # which course corresponds to the given context ID
      return render_failure(:unpaired) if course.nil?

      if !UserIsCourseStudent[course: course, user: current_user, include_dropped_students: true]
        # Enroll into the course
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

    Lti::Context.create! platform: platform, context: context, course: course

    # Continue with the launch
    launch
  end

  protected

  def lti_auth
    @lti_auth ||= request.env['omniauth.auth'] || session['lti_auth']
  end

  def uid
    lti_auth.uid
  end

  def lti_auth_raw_info
    lti_auth.extra.raw_info
  end

  def platform
    @platform ||= Lti::Platform.find_by! guid: session['lti_guid']
  end

  def lti_user
    User::Models::Profile.joins(:lti_users).find_by(
      lti_users: { platform: platform, uid: uid }
    )
  end

  def roles
    lti_auth_raw_info['https://purl.imsglobal.org/spec/lti/claim/roles'] || []
  end

  def context_roles
    @context_roles ||= roles.select do |role|
      role.starts_with? 'http://purl.imsglobal.org/vocab/lis/v2/membership#'
    end.map { |role| role.sub('http://purl.imsglobal.org/vocab/lis/v2/membership#', '') }
  end

  def course_admin?
    (COURSE_ADMIN_ROLES & context_roles).any?
  end

  def student?
    context_roles.include? 'Learner'
  end

  def context
    lti_auth_raw_info['https://purl.imsglobal.org/spec/lti/claim/context']
  end

  def course
    @course ||= CourseMembership::Models::Course.joins(:lti_contexts).find_by(
      lti_contexts: { lti_platform_id: platform.id, context_id: context['id'] }
    )
  end

  def target_link_uri
    uri = lti_auth_raw_info['https://purl.imsglobal.org/spec/lti/claim/target_link_uri']
    path = Addressable::URI.parse(uri).path
    path.starts_with?('/lms/') || path.starts_with?('/lti/') ? course_dashboard_url(course) : uri
  end

  def clear_lti_session
    session.delete 'lti_guid'
    session.delete 'lti_auth'
  end

  def render_failure(name)
    render "lti/failures/#{name}"
    clear_lti_session
  end
end
