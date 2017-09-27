class LmsController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:launch, :ci_launch]
  skip_before_filter :authenticate_user!, only: [:configuration, :launch, :launch_authenticate, :ci_launch]

  before_filter :allow_embedding_in_iframe, only: [:launch, :ci_launch]

  layout false

  def configuration; end

  def launch
    begin
      launch = Lms::Launch.from_request(request)

      Rails.logger.debug { launch.formatted_data(include_everything: true) }

      # Persist the launch so we can load it after return from Accounts. Since
      # these persisted launches are going to be kept around for a while for
      # debugging, persist before any errors are detected

      session[:launch_id] = launch.persist!

      # Do some early error checking

      fail_for_unsupported_role and return if !(launch.is_student? || launch.is_instructor?)

      fail_for_missing_required_fields(launch) and return if launch.missing_required_fields.any?

      # For the time being, all apps are course-owned, meaning we can infer the
      # course associated to a launch by looking at the app keys inside the launch.
      # This means if we don't have a context yet, we should be able to autocreate it.
      # Do that here, and freak out if we can't.  When we add admin-installed apps,
      # remove the freak-out.

      context = launch.context

      if context.nil? && launch.can_auto_create_context?
        context = launch.auto_create_context!
      end

      raise "Context was not created for launch #{session[:launch_id]}" if context.nil?

      # FUTURE FUNCTIONALITY SKETCH
      #
      # When we let admins install Tutor, we'll need teachers to pair their Tutor course
      # with their LMS course.  At that point, something like the following logic will
      # be needed.  context won't be nil now because all apps are owned by courses, so
      # the auto create above should succeed.
      #
      # if context.nil?
      #   if launch.is_student?
      #     # Show a "your teacher needs do something before you can open Tutor" message
      #   else
      #     # teacher will need to pair their course to the LMS course after
      #     # authentication.  The `authenticate` action will either need to redirect
      #     # to a `pair` action/flow, or `complete_launch` will need to redirect to
      #     # such a flow before it calls its handler.
      #   end
      # end

      fail_for_lms_disabled(launch, context) and return if !context.course.is_lms_enabled

    rescue Lms::Launch::LmsDisabled => ee
      fail_for_lms_disabled(launch, context) and return
    rescue Lms::Launch::CourseKeysAlreadyUsed => ee
      fail_for_course_keys_already_used(launch) and return
    rescue Lms::Launch::HandledError => ee
      fail_with_catchall_message(ee) and return
    end
  end

  def launch_authenticate
    launch = Lms::Launch.from_id(session[:launch_id])

    # Always send users to accounts when a launch happens.  We may decide
    # later to skip accounts when the user is already logged in, but in
    # that case we will want to make sure that the launching user is in
    # fact the user who is logged in, for which we'd need to track a link
    # between LMS user ID and local user ID.  For users who have launched
    # before, the trip to Accounts and back should be pretty quick / invisible.

    redirect_to openstax_accounts.login_url(
      sp: OpenStax::Api::Params.sign(
        params: {
          uuid:  launch.lms_user_id,
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
    launch = Lms::Launch.from_id(session.delete(:launch_id))

    # Later may be nil if we are supposed to handle admin-installed apps with a pairing step here
    raise "Context cannot be nil" if launch.context.nil?

    # Make TC updates inline because queueing a background job is probably as much work
    # and we might want things like updated LMS admin contact info immediately
    launch.update_tool_consumer_metadata!

    # Add the user as a teacher or student

    course = launch.context.course

    if launch.is_student?
      if launch.is_assignment?
        # For assignment launches, store the grade passback info.  We are currently
        # only doing course-level grade sync, so store the grade attached to the Student.
        # Since we may not actually have a Student record yet (if enrollment hasn't completed),
        # we really attach it to the combination of course and user (which is essentially what
        # a Student later records).  It is possible that a teacher could add the Tutor assignment
        # more than once, so we could have multiple callback infos for ever course/user combination.

        # TODO change to launch.create_score_callback_if_missing(caller.to_model) - a lot of above
        # comment goes into Launch method

        Lms::Models::CourseScoreCallback.find_or_create_by(
          result_sourcedid: launch.result_sourcedid,
          outcome_url: launch.outcome_url,
          course: course,
          profile: current_user.to_model
        )
      end

      # Note if the user is not yet a student in the course, so they can be sent through the
      # LMS-optimized enrollment flow.

      if !UserIsCourseStudent[course: course, user: current_user]
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

  def ci_launch
    begin
      @launch = Lms::Launch.from_request(request)
    rescue Lms::Launch::Error => ee
      fail_with_catchall_message(ee) and return
    end
  end

  protected

  def allow_embedding_in_iframe
    response.headers["X-FRAME-OPTIONS"] = 'ALLOWALL'
  end

  def fail_for_lms_disabled(launch, context)
    Rails.logger.info { "Attempting to launch (#{session[:launch_id]}) into an " \
                        "LMS-disabled course (#{context.nil? ? 'not set' : context.course.id})" }
    render(:fail_lms_disabled, status: :unprocessable_entity)
  end

  def fail_for_unsupported_role
    Rails.logger.info { "Unsupported role launched in launch #{session[:launch_id]}"}
    render(:fail_unsupported_role, status: :unprocessable_entity)
  end

  def fail_for_missing_required_fields(launch)
    Rails.logger.info { "Launch #{session[:launch_id]} is missing required fields: " \
                        "#{launch.missing_required_fields}" }
    render(:fail_missing_required_fields, locals: { launch: launch }, status: :unprocessable_entity)
  end

  def fail_for_course_keys_already_used(launch)
    Rails.logger.info { "Launch #{session[:launch_id]} failing because course keys already used for another context"}
    render :fail_course_keys_already_used, locals: { launch: launch }, status: :unprocessable_entity
  end

  def fail_with_catchall_message(exception)
    Rails.logger.info { "Launch failed: #{exception.try(:message)}" }
    render(:fail_catchall, status: :unprocessable_entity)
  end

end
