class LtiController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :callback # This is handled by Omniauth
  skip_before_action :authenticate_user!, only: :callback # Login happens right after this step

  layout false

  # This endpoint is reached after the OpenID Connect login (handled by omniauth_openid_connect)
  # Send to accounts for login, then back to launch endpoint
  # This is equivalent to launch_authenticate in the old LmsController
  def callback
    return fail_for_unpaired if student? && course.nil?

    redirect_to openstax_accounts.login_url return_to: lti_launch_url
  end

  # Associate the logged-in user with the LTI info saved in the session
  # Instructors are redirected to the pair page or added to the course
  # Students are enrolled into the course
  # Users are redirected to the target_link_uri afterwards unless that would cause a loop
  def launch
    # Find the course by LTI's context_id
    if student?
      # Instructor needs to pair the course first so we know
      # which course corresponds to the given context ID
      return render(:fail_for_unpaired) if course.nil?

      if UserIsCourseStudent[course: course, user: current_user, include_dropped_students: true]
        # Already a student, send back to course
        redirect_to target_link_uri
      else
        # Enroll into course
        redirect_to token_enroll_url(course.uuid), return_to: target_link_uri
      end
    elsif instructor? || administrator?
      if course.nil?
        # Initial pairing
        redirect_to lti_pair_url if CourseMembership::Models::Teacher.joins(:role).where(
          deleted_at: nil, role: { profile: current_user }
        ).exists? || current_user.account.confirmed_faculty?

        # No courses to pair and cannot create new courses
        return render(:fail_for_no_courses)
      end

      # Another instructor launches after initial pairing, so add them as an instructor
      AddUserAsCourseTeacher[user: current_user, course: course] \
        if instructor? && !UserIsCourseTeacher[user: current_user, course: course]

      redirect_to target_link_uri
    end
  end

  def pair
    # pair renders a stripped down HTML page that renders a React UI
    render layout: false
  end

  protected

  def lti_session
    @lti_session ||= session['lti'] || {}
  end

  def student?
    lti_session['role'] == 'learner'
  end

  def instructor?
    lti_session['role'] == 'instructor'
  end

  def administrator?
    lti_session['role'] == 'administrator'
  end

  def course
    @course ||= CourseMembership::Models::Course.joins(contexts: :platform).find_by(
      contexts: { platform: { guid: lti_session['guid'] }, context_id: lti_session['context_id'] }
    )
  end

  def target_link_uri
    path = Addressable::URI.parse(lti_session['target_link_uri']).path
    path.starts_with?('/lms/') || path.starts_with?('/lti/') ?
                course_dashboard_url(course) : target_link_uri
  end
end
