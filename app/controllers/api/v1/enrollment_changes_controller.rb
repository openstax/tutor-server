class Api::V1::EnrollmentChangesController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Indicates the intent of a user to enroll in a course or to switch periods'
    description <<-EOS
      EnrollmentChanges indicate that a user has requested to change their status in a course.
      The changes currently need to be approved by the requesting user to be effective.
    EOS
  end

  api :POST, '/enrollment_changes',
             'Creates a new EnrollmentChange request or updates the current one'
  description <<-EOS
    Creates a new EnrollmentChange object, indicating the user's intention to enroll in a course
    or to switch periods.

    Input:
    #{json_schema(Api::V1::NewEnrollmentChangeRepresenter, include: :writeable)}

    Output:
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}
  EOS
  def create
    OSU::AccessPolicy.require_action_allowed!(:create, current_api_user,
                                              CourseMembership::EnrollmentChange)

    enrollment_params = OpenStruct.new
    consume!(enrollment_params, represent_with: Api::V1::NewEnrollmentChangeRepresenter)

    # Find only CC periods
    period = CourseMembership::Models::Period.joins(course: :profile).find_by(
      enrollment_code: enrollment_params.enrollment_code,
      course: { profile: { is_concept_coach: true } }
    )

    if period.nil?
      render_api_errors(:invalid_enrollment_code)
      return
    end

    if enrollment_params.cnx_book_id.present?
      ecosystem = GetCourseEcosystem[course: period.course]

      if ecosystem.books.first.cnx_id != enrollment_params.cnx_book_id
        render_api_errors(:enrollment_code_does_not_match_book)
        return
      end
    end

    result = CourseMembership::CreateEnrollmentChange.call(user: current_human_user,
                                                           period: period)

    if result.errors.empty?
      respond_with result.outputs.enrollment_change,
                   represent_with: Api::V1::EnrollmentChangeRepresenter,
                   location: nil
    else
      render_api_errors(:already_enrolled)
    end
  end

  api :PUT, '/enrollment_changes/:enrollment_change_id/approve',
            'Approves an EnrollmentChange request'
  description <<-EOS
    Approves an EnrollmentChange object, causing the user's enrollment status to update.

    Output:
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}
  EOS
  def approve
    model = CourseMembership::Models::EnrollmentChange.find(params[:id])
    strategy = CourseMembership::Strategies::Direct::EnrollmentChange.new(model)
    enrollment_change = CourseMembership::EnrollmentChange.new(strategy: strategy)
    OSU::AccessPolicy.require_action_allowed!(:approve, current_api_user, enrollment_change)

    result = CourseMembership::ApproveEnrollmentChange.call(enrollment_change: enrollment_change,
                                                            approved_by: current_human_user)

    if result.errors.empty?
      respond_with result.outputs.enrollment_change,
                   represent_with: Api::V1::EnrollmentChangeRepresenter,
                   responder: ResponderWithPutContent
    else
      render_api_errors(:already_approved)
    end
  end

end
