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
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}
  EOS
  def create
    raise NotImplementedError
  end

  api :PUT, '/enrollment_changes/:enrollment_change_id/approve',
            'Approves an EnrollmentChange request'
  description <<-EOS
    Approves an EnrollmentChange object, causing the user's enrollment status to update.
    #{json_schema(Api::V1::EnrollmentChangeRepresenter, include: :readable)}
  EOS
  def approve
    raise NotImplementedError
  end

end
