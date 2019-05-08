class Api::V1::EnrollmentController < Api::V1::ApiController


  resource_description do
    api_versions "v1"
    short_description 'Indicates the intent of a user to enroll in a course or to switch periods'
    description <<-EOS
      EnrollmentChanges indicate that a user has requested to change their status in a course.
      The changes currently need to be approved by the requesting user to be effective.
    EOS
  end

  api :GET, '/:course_uuid/choices', 'Returns limited information for a given course uuid'
  description <<-EOS
    Returns course and period information for a course identified by its UUID.
    Can be called by any logged in user, but only returns the course name and enrollment codes
    #{json_schema(Api::V1::PeriodRepresenter, include: :readable)}
  EOS
  def choices
    course = CourseProfile::Models::Course.find_by!(uuid: params[:id])
    respond_with(
      course,
      represent_with: Api::V1::CourseEnrollmentsRepresenter,
      location: nil
    )
  end

  api :POST, '/prevalidate', 'Check if an enrollment code is valid for a given book uuid'
  description <<-EOS
    If the enrollment code is valid, returns the associated course and period.
    Otherwise, returns an error code.
    May be called by an anonymous (non-logged in) user.

    Input:
    #{json_schema(Api::V1::NewEnrollmentChangeRepresenter, include: :writeable)}

    Output:
    #{json_schema(Api::V1::Enrollment::PeriodWithCourseRepresenter, include: :readable)}

    Possible error codes:
      invalid_enrollment_code
      course_ended
      enrollment_code_does_not_match_book
  EOS
  def prevalidate
    enrollment_params = OpenStruct.new
    consume!(enrollment_params, represent_with: Api::V1::NewEnrollmentChangeRepresenter)

    result = CourseMembership::ValidateEnrollmentParameters.call(
      enrollment_code: enrollment_params.enrollment_code,
      book_uuid: enrollment_params.book_uuid
    )
    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs.period,
                   represent_with: Api::V1::Enrollment::PeriodWithCourseRepresenter,
                   location: nil
    end
  end

  api :POST, '/enrollment', 'Creates a new EnrollmentChange request or updates the current one'
  description <<-EOS
    Creates a new EnrollmentChange object, indicating the user's intention to enroll in a course
    or to switch periods.

    Input:
    #{json_schema(Api::V1::NewEnrollmentChangeRepresenter, include: :writeable)}

    Output:
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}

    Possible error codes:
      invalid_enrollment_code
      preview_course
      course_ended
      is_teacher (the user is a teacher)
      enrollment_code_does_not_match_book
      dropped_student (dropped students cannot re-enroll by themselves)
      already_enrolled
  EOS
  def create
    OSU::AccessPolicy.require_action_allowed!(
      :create, current_api_user, CourseMembership::EnrollmentChange
    )

    enrollment_params = OpenStruct.new
    consume!(enrollment_params, represent_with: Api::V1::NewEnrollmentChangeRepresenter)

    result = CourseMembership::CreateEnrollmentChange.call(
      user: current_human_user,
      enrollment_code: enrollment_params.enrollment_code,
      book_uuid: enrollment_params.book_uuid
    )

    render_api_errors(result.errors) || respond_with(
      result.outputs.enrollment_change,
      represent_with: Api::V1::EnrollmentChangeRepresenter,
      location: nil
    )
  end

  api :PUT, '/enrollment/:enrollment_change_id/approve',
            'Approves an EnrollmentChange request'
  description <<-EOS
    Approves an EnrollmentChange object, causing the user's enrollment status to update.

    Input:
    #{json_schema(Api::V1::ApproveEnrollmentChangeRepresenter, include: :writeable)}

    Output:
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}

    Possible error codes:
      already_approved
      already_rejected
      already_processed
      taken (The provided student identifier is already present in the same course)
  EOS
  def approve
    CourseMembership::Models::EnrollmentChange.transaction do
      model = CourseMembership::Models::EnrollmentChange.lock.find(params[:id])
      enrollment_change = CourseMembership::EnrollmentChange.new(strategy: model.wrap)
      OSU::AccessPolicy.require_action_allowed!(:approve, current_api_user, enrollment_change)

      approve_params = OpenStruct.new
      consume!(approve_params, represent_with: Api::V1::ApproveEnrollmentChangeRepresenter)

      model.approve_by(current_human_user).save if enrollment_change.pending?

      result = CourseMembership::ProcessEnrollmentChange.call(
        enrollment_change: enrollment_change, student_identifier: approve_params.student_identifier
      )

      (render_api_errors(result.errors) && raise(ActiveRecord::Rollback)) || respond_with(
        result.outputs.enrollment_change,
        represent_with: Api::V1::EnrollmentChangeRepresenter,
        responder: ResponderWithPutPatchDeleteContent
      )
    end
  end

end
