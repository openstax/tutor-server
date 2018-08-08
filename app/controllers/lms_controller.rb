class LmsController < ApplicationController

  # The LMS controller manages non-API LMS behavior, including:
  #
  #   * providing config info used when installing the Tutor app in an LMS
  #   * running the standard launch (e.g. student or teacher accessing the
  #     "Tutor" assignment)
  #   * running the "content item" launch that helps teachers get the "Tutor"
  #     assignment link in to their LMS course.

  skip_before_filter :verify_authenticity_token, only: [:launch, :ci_launch]
  skip_before_filter :authenticate_user!, only: [:configuration, :launch, :launch_authenticate, :ci_launch]

  before_filter :allow_iframe_access, only: [:launch, :ci_launch]

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
    rescue => ee
      debugger
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

      log(:debug) { launch.formatted_data(include_everything: true) }

      # Persist the launch so we can load it after return from Accounts. Since
      # these persisted launches are going to be kept around for a while for
      # debugging, persist before any errors are detected

      session[:launch_id] = launch.persist!

      # Do some early error checking


      fail_for_unsupported_role and return if !(launch.is_student? || launch.is_instructor?)

      fail_for_missing_required_fields(launch) and return if launch.missing_required_fields.any?

      context = launch.attempt_context_creation

      # FUTURE FUNCTIONALITY SKETCH
      #
      # context won't be nil now because all apps are owned by courses, so
      # the auto create above should succeed.
      #
      # When we let admins install Tutor, we'll need teachers to pair
      # Tutor course with their LMS course.  At that point, something like
      # the following logic will be needed.
      #

      if context.course.nil?
        if launch.is_instructor?
          # teacher will need to pair their course to the LMS course
          if current_user.is_anonymous?
            redirect_to_accounts(return_to: lms_launch_url, context_id: context.id) and return
          end

        else
          # Show a "your teacher needs do something before you can open Tutor" message
          fail_for_unpaired and return
          after
          # authentication.  The `authenticate` action will either need to redirect
          # to a `pair` action/flow, or `complete_launch` will need to redirect to
          # such a flow before it calls its handler.
        end
      end

      fail_for_lms_disabled(launch, context) and return if !context.course.is_lms_enabled

    rescue Lms::Launch::LmsDisabled => ee
      fail_for_lms_disabled(launch, context) and return
    rescue Lms::Launch::CourseKeysAlreadyUsed => ee
      fail_for_course_keys_already_used(launch) and return
    rescue Lms::Launch::AlreadyUsed => ee
      fail_for_already_used and return
    rescue Lms::Launch::AppNotFound, Lms::Launch::InvalidSignature => ee
      fail_for_invalid_key_secret(launch) and return
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
      launch = Lms::Launch.from_id(session[:launch_id])
    rescue Lms::Launch::CouldNotLoadLaunch => ee
      fail_for_already_used and return
    end

    # Always send users to accounts when a launch happens.  We may decide
    # later to skip accounts when the user is already logged in, but in
    # that case we will want to make sure that the launching user is in
    # fact the user who is logged in, for which we'd need to track a link
    # between LMS user ID and local user ID.  For users who have launched
    # before, the trip to Accounts and back should be pretty quick / invisible.

    redirect_to openstax_accounts.login_url(
      sp: OpenStax::Api::Params.sign(
        params: {
          uuid:  launch.lms_tc_scoped_user_id,
          name:  launch.full_name,
          email: launch.email,
          school: launch.school,
          role:  launch.role
        },
        secret: OpenStax::Accounts.configuration.openstax_application_secret
      ),
      return_to: lms_complete_launch_url
    )
  end

  def complete_launch
    # Part 3 of 3 in how Tutor processes the launch - gets the now authenticated user to
    # their course (or the enrollment screen into it)

    begin
      launch = Lms::Launch.from_id(session.delete(:launch_id))
    rescue Lms::Launch::CouldNotLoadLaunch => ee
      fail_for_already_used and return
    end

    # Later may be nil if we are supposed to handle admin-installed apps with a pairing step here
    raise "Context cannot be nil" if launch.context.nil?

    # Make TC updates inline because queueing a background job is probably as much work
    # and we might want things like updated LMS admin contact info immediately
    launch.update_tool_consumer_metadata!

    # Add the user as a teacher or student

    course = launch.context.course

    if launch.is_student?
      launch.store_score_callback(current_user)

      # Note if the user is not yet a student in the course, so they can be sent through the
      # LMS-optimized enrollment flow.

      if !UserIsCourseStudent[course: course, user: current_user, include_dropped_students: true]
        is_unenrolled_student = true
      end
    elsif launch.is_instructor?
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

  protected

  def redirect_to_accounts(return_to: nil)
    redirect_to openstax_accounts.login_url(
                  sp: OpenStax::Api::Params.sign(
                    params: {
                      uuid:  launch.lms_tc_scoped_user_id,
                      name:  launch.full_name,
                      email: launch.email,
                      school: launch.school,
                      role:  launch.role
                    },
                    secret: OpenStax::Accounts.configuration.openstax_application_secret
                  ),
                  return_to: return_to
                )
  end

  def fail_for_unpaired
    log(:info) { "Attempting to launch (#{session[:launch_id]}) into an not-yet-paired course" }
    render_minimal_error(:fail_unpaired)
  end

  def fail_for_lms_disabled(launch, context)
    log(:info) { "Attempting to launch (#{session[:launch_id]}) into an " \
                 "LMS-disabled course (#{context.nil? ? 'not set' : context.course.id})" }
    render_minimal_error(:fail_lms_disabled, locals: { launch: launch })
  end

  def fail_for_unsupported_role
    log(:info) { "Unsupported role launched in launch #{session[:launch_id]}"}
    render_minimal_error(:fail_unsupported_role)
  end

  def fail_for_missing_required_fields(launch)
    log(:info) { "Launch #{session[:launch_id]} is missing required fields: " \
                 "#{launch.missing_required_fields}" }
    render_minimal_error(:fail_missing_required_fields, locals: { launch: launch })
  end

  def fail_for_course_keys_already_used(launch)
    log(:info) { "Launch #{session[:launch_id]} failing because course keys already used for another context"}
    render_minimal_error(:fail_course_keys_already_used, locals: { launch: launch })
  end

  def fail_for_already_used
    log(:info) { "Nonce reused in launch #{session[:launch_id]}"}
    render_minimal_error(:fail_already_used)
  end

  def fail_for_invalid_key_secret(launch)
    log(:info) { "Invalid key and/or secret #{session[:launch_id]}"}
    render_minimal_error(:fail_invalid_key_secret, locals: { launch: launch })
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
