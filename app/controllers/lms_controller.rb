class LmsController < ApplicationController

  # The LMS controller manages non-API LMS behavior, including:
  #
  #   * providing config info used when installing the Tutor app in an LMS
  #   * running the standard launch (e.g. student or teacher accessing the
  #     "Tutor" assignment)
  #   * running the "content item" launch that helps teachers get the "Tutor"
  #     assignment link in to their LMS course.

  skip_before_action :verify_authenticity_token, only: [:launch, :ci_launch]
  skip_before_action :authenticate_user!, only: [:configuration, :launch, :launch_authenticate, :ci_launch]

  before_action :allow_iframe_access, only: [:launch, :ci_launch]

  layout false

  def configuration
    # provides configuration XML used when installing the Tutor app in an LMS
  end

  def ci_launch
    # The "content item" launch.  The launch has slightly different parameters (e.g.
    # a `content_item_return_url` where our rendered HTML needs to POST to); most of
    # of the interesting work here happens in the view.

    begin
      @launch = Lms::Launch.from_request(request)
      @launch.validate!
    rescue StandardError => ee
      fail_with_catchall_message(ee) and return
    end
  end

  def launch
    # Part 1 of 3 in how Tutor processes the launch.  Validates the launch, does
    # some error checking, makes the link between the right Tutor course and the
    # LMS course being launched from, renders a page that makes sure we are not
    # trapped in an iframe for the rest of the launch.

    begin
      launch = Lms::Launch.from_request(request)
      launch.validate!

      log(:debug) { launch.formatted_data(include_everything: true) }

      fail_for_missing_required_fields(launch) and return if launch.missing_required_fields.any?
      # Persist the launch so we can load it after return from Accounts. Since
      # these persisted launches are going to be kept around for a while for
      # debugging, persist before any errors are detected

      # set launch uuid as param in url, this may be loaded inside iframe where the cookie based session may be blocked
      @next_url = lms_launch_authenticate_path(launch_uuid: launch.persist!)

      # Do some early error checking
      fail_for_unsupported_role and return if !(launch.is_student? || launch.is_instructor?)

      context = launch.context
      if context.course.nil?
        if launch.is_student?
          # Show a "your teacher needs do something before you can open Tutor" message
          fail_for_unpaired and return

          # authentication.  The `authenticate` action will either need to redirect
          # to a `pair` action/flow, or `complete_launch` will need to redirect to
          # such a flow before it calls its handler.
        end
      end

      fail_for_lms_disabled(launch, context) and return if context.course and !context.course.is_lms_enabled

    rescue Lms::Launch::LmsDisabled => ee
      fail_for_lms_disabled(launch, context) and return
    rescue Lms::Launch::CourseEnded => ee
      fail_for_course_ended(launch) and return
    rescue Lms::Launch::CourseScoreInUse => ee
      fail_for_course_score_in_use(launch) and return
    rescue Lms::Launch::AppNotFound
      fail_for_app_not_found(launch) and return
    rescue Lms::Launch::InvalidSignature => ee
      fail_for_invalid_signature(launch) and return
    rescue Lms::Launch::ExpiredTimestamp => ee
      fail_for_expired_timestamp(launch) and return
    rescue Lms::Launch::InvalidTimestamp => ee
      fail_for_invalid_timestamp(launch) and return
    rescue Lms::Launch::NonceAlreadyUsed => ee
      fail_for_nonce_already_used(launch) and return
    rescue Lms::Launch::HandledError => ee
      fail_with_catchall_message(ee) and return
    end

    # renders page that redirects to the authenticate step if the page is not in an
    # iframe; if it is in an iframe, gives the user a link to the authenticate step
    # that will open in a new tab
  end

  def launch_authenticate
    # Part 2 of 3 in how Tutor processes the launch

    begin
      launch = Lms::Launch.from_uuid(params[:launch_uuid])
      launch.validate!
      
      session[:launch_uuid] = params[:launch_uuid] # we're now outside iframe and can use session
    rescue Lms::Launch::CouldNotLoadLaunch => ee
      fail_for_could_not_load_launch and return
    end

    redirect_to openstax_accounts.login_url(return_to: lms_complete_launch_url)
  end

  def complete_launch
    # Part 3 of 3 in how Tutor processes the launch - gets the now authenticated user to
    # their course (or the enrollment screen into it)
    launch = Lms::Launch.from_uuid(session[:launch_uuid])
    launch.validate!
    process_completed_launch(launch)
  rescue Lms::Launch::CouldNotLoadLaunch => ee
    fail_for_could_not_load_launch
  rescue Lms::Launch::CourseScoreInUse => ee
    fail_for_course_score_in_use(launch)
  end

  def process_completed_launch(launch)
    # Later may be nil if we are supposed to handle admin-installed apps with a pairing step here
    raise "Context cannot be nil" if launch.context.nil?

    # Make TC updates inline because queueing a background job is probably as much work
    # and we might want things like updated LMS admin contact info immediately
    launch.update_tool_consumer_metadata!

    # Add the user as a teacher or student
    course = launch.context.course
    if launch.is_student?
      # students were checked to ensure the launch had
      # a course in step 2 (launch_authenticate)
      launch.store_score_callback(current_user)
      # Note if the user is not yet a student in the course, so they can be sent through the
      # LMS-optimized enrollment flow.
      if !UserIsCourseStudent[course: course, user: current_user, include_dropped_students: true]
        is_unenrolled_student = true
      end
    elsif launch.is_instructor?
      if course.nil?
        redirect_to lms_pair_url and return
      end
      if !UserIsCourseTeacher[user: current_user, course: course]
        AddUserAsCourseTeacher[user: current_user, course: course]
      end
    end

    if is_unenrolled_student
      redirect_to token_enroll_url(course.uuid)
    else
      redirect_to course_dashboard_url(course)
    end
  end

  def pair
    # pair renders a stripped down HTML page that renders a React UI
    render layout: false
  end

  protected

  def fail_for_unpaired
    log(:info) { "Attempting to launch (#{session[:launch_uuid]}) into an not-yet-paired course" }
    render_minimal_error(:fail_unpaired)
  end

  def fail_for_unsupported_role
    log(:info) { "Unsupported role launched in launch #{session[:launch_uuid]}"}
    render_minimal_error(:fail_unsupported_role)
  end

  def fail_for_could_not_load_launch
    log(:info) { "Could not load launch #{session[:launch_uuid]}"}
    render_minimal_error(:fail_could_not_load_launch)
  end

  def fail_for_lms_disabled(launch, context)
    log(:info) { "Attempting to launch (#{session[:launch_uuid]}) into an " \
                 "LMS-disabled course (#{context.nil? ? 'not set' : context.course.id})" }
    Raven.capture_message('LMS launch into disabled course', extra: {
      launch_uuid: session[:launch_uuid],
      course: context.nil? ? 'not set' : context.course.id,
    })
    render_minimal_error(:fail_lms_disabled, locals: { launch: launch })
  end

  def fail_for_course_ended(launch)
    log(:info) { "Attempting to launch (#{session[:launch_uuid]}) into a course that has ended" }
    render_minimal_error(:fail_course_ended, locals: { launch: launch })
  end

  def fail_for_missing_required_fields(launch)
    log(:info) { "Launch #{session[:launch_uuid]} is missing required fields: " \
                 "#{launch.missing_required_fields}" }
    render_minimal_error(:fail_missing_required_fields, locals: { launch: launch })
  end

  def fail_for_course_score_in_use(launch)
    log(:error) { "Course Score Callback is already taken #{launch.result_sourcedid} : #{launch.outcome_url}" }
    Raven.capture_message('LMS course score callback in use', extra: {
      id: launch.result_sourcedid,
      url: launch.outcome_url,
    })
    render_minimal_error(:fail_course_score_in_use)
  end

  def fail_for_app_not_found(launch)
    log(:info) { "App not found #{session[:launch_uuid]}" }
    render_minimal_error(:fail_app_not_found, locals: { launch: launch })
  end

  def fail_for_invalid_signature(launch)
    log(:info) { "Invalid signature #{session[:launch_uuid]}" }
    render_minimal_error(:fail_invalid_signature, locals: { launch: launch })
  end

  def fail_for_expired_timestamp(launch)
    log(:info) { "Expired timestamp #{session[:launch_uuid]}" }
    render_minimal_error(:fail_expired_timestamp, locals: { launch: launch })
  end

  def fail_for_invalid_timestamp(launch)
    log(:info) { "Invalid timestamp #{session[:launch_uuid]}" }
    render_minimal_error(:fail_invalid_timestamp, locals: { launch: launch })
  end

  def fail_for_nonce_already_used(launch)
    log(:info) { "Nonce already used #{session[:launch_uuid]}" }
    Raven.capture_message('LMS nonce already used', extra: { nonce: session[:launch_uuid] })
    render_minimal_error(:fail_nonce_already_used, locals: { launch: launch })
  end

  def fail_with_catchall_message(exception)
    log(:error) { "Launch failed: #{exception.try(:message)}" }
    render_minimal_error(:fail_catchall)
  end

  def render_minimal_error(action, options={})
    render(action, options.merge(layout: 'minimal_error', status: :unprocessable_entity))
  end

  def log(level, &block)
    Rails.logger.tagged(self.class.name) { |logger| logger.public_send(level, &block) }
  end

end
