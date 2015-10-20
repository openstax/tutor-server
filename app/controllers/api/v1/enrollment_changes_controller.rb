class EnrollmentChangesController < ApplicationController

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
    If a pending EnrollmentChange already exists, that record is updated instead.

    Input:
    #{json_schema(Api::V1::NewEnrollmentChangeRepresenter, include: :writeable)}

    Output:
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}
  EOS
  def create
    enrollment_params = OpenStruct.new
    consume!(enrollment_params, represent_with: Api::V1::NewEnrollmentChangeRepresenter)

    CreateEnrollmentChange[user: current_human_user,
                           enrollment_code: enrollment_params.enrollment_code,
                           book_cnx_id: enrollment_params.book_cnx_id]
  end

  api :PUT, '/enrollment_changes/:enrollment_change_id/approve',
            'Approves an EnrollmentChange request'
  description <<-EOS
    Approves an EnrollmentChange object, causing the user's enrollment status to update.

    Output:
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}
  EOS
  def approve
    enrollment_change = CourseMembership::Models::EnrollmentChange.find(params[:id])

    ApproveEnrollmentChange[enrollment_change: enrollment_change, approved_by: current_human_user]
  end

end
