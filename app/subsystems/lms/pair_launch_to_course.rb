class Lms::PairLaunchToCourse

  lev_routine

  def exec(launch_uuid:, course:)
    outputs.success = false
    begin
      launch = Lms::Launch.from_uuid(launch_uuid)
      launch.validate!
    rescue Lms::Launch::CouldNotLoadLaunch => ee
      fatal_error(code: :lms_launch_doesnt_exist, message: "LMS Launch was not found")
    end

    launch.context.course = course
    launch.context.save
    transfer_errors_from(launch.context, {type: :verbatim}, true)

    course.update_attributes!(is_lms_enabling_allowed: true, is_lms_enabled: true)
    transfer_errors_from(course, {type: :verbatim})
    outputs.success = true
  end
end
