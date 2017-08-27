require 'active_support/core_ext/module/delegation'

class Lms::ProcessLaunch

  lev_routine

  def exec(launch, user)
    raise "`launch` cannot be nil" if launch.nil?
    raise "`user` cannot be nil" if user.nil?

    @launch = launch

    # Get the tool consumer, and update its metadata as needed

    tool_consumer ||= Lms::Models::ToolConsumer.find_or_create_by!(guid: tool_consumer_instance_guid)
    update_tool_consumer_metadata(tool_consumer)

    # Get or create the context so we can know the course to launch into

    context = Lms::Models::Context.joins{tool_consumer}
                                  .eager_load(:course)
                                  .where{lti_id == context_id}
                                  .where{tool_consumer.guid == tool_consumer_instance_guid}
                                  .first

    if context.nil?
      # Figure out the course so we can build a context that points to it
      app_owner = launch.app.owner

      if app_owner.is_a?(CourseProfile::Models::Course)
        course = app_owner
        context = Lms::Models::Context.create(
          lti_id: context_id,
          tool_consumer: tool_consumer,
          course: course
        )
      else
        # When we allow admin-installed apps, will need to handle this case, but not now.
        fatal_error(code: :no_context_and_app_is_not_course_owned)
      end
    else
      course = context.course
    end

    # Add the user as a teacher or student

    if launch.is_student?
      # Make sure the user is in the course as a student

      # TODO how do we know which period to add them to?  Possible that we could just add
      # the student to the course and then on the FE recognize that they are without period
      # and have them self-select their period?

      student = nil # FIXME obviously :-)

      if launch.is_assignment?
        # For assignment launches, store the grade passback info.  We are currently
        # only doing course-level grade sync, so store the grade attached to the Student.
        # It is possible that a teacher could add the Tutor assignment more than once,
        # so keep track of those multiple callback infos by hanging records off of Student.

        course_grade_callback = Lms::Models::CourseGradeCallback.find_or_create_by(
                                  result_sourcedid: launch.result_sourcedid,
                                  outcome_url: launch.outcome_url,
                                  student: student
                                )
      end
    elsif launch.is_instructor?
      if !UserIsCourseTeacher[user: requestor, course: course]
        AddUserAsCourseTeacher[course: course, user: user]
      end
    end

    # Output the course so that the launch can redirect to its dashboard

    outputs.course = course
  end

  protected

  delegate :tool_consumer_instance_guid, :context_id, to: :message

  def update_tool_consumer_metadata(tool_consumer)
    # TODO use the data in the launch to update what we know about the tool consumer
    # includes admin email addresses, LMS version, etc.  Do this inline because the
    # savings of doing it in a background job probably isn't worth it, and we might
    # want latest LMS admin contact info immediately
  end

  def message
    @launch.message
  end

end
