class Api::V1::StudentsController < Api::V1::ApiController

  before_action :get_student, only: [ :update, :destroy, :restore ]
  before_action :get_course_student, only: :update_self
  before_action :error_if_student_and_needs_to_pay, only: [ :update_self, :update ]

  resource_description do
    api_versions "v1"
    short_description 'Represents a user in a course period'
    description <<-EOS
      Students are users who are part of a course period.
      Teachers are allowed to create and delete students and move them between periods.
    EOS
  end

  api :PATCH, '/user/courses/:course_id/student', "Updates the current student's information"
  description <<-EOS
    Updates the current student's information.
    Currently, only the student_identifier can be modified.
    #{json_schema(Api::V1::StudentSelfUpdateRepresenter, include: :writeable)}
  EOS
  def update_self
    consume!(@student, represent_with: Api::V1::StudentSelfUpdateRepresenter)

    if @student.save
      # http://stackoverflow.com/a/27413178
      respond_with @student, responder: ResponderWithPutPatchDeleteContent,
                             represent_with: Api::V1::StudentSelfUpdateRepresenter
    else
      render_api_errors(@student.errors)
    end
  end

  api :PATCH, '/students/:student_id', "Updates a student's information"
  description <<-EOS
    Updates a student's information.
    Currently, only the period can be modified.
    #{json_schema(Api::V1::StudentRepresenter, include: :writeable)}
  EOS
  def update
    period_update_result = nil
    @student.with_lock do
      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @student)
      consume!(@student, represent_with: Api::V1::StudentTeacherUpdateRepresenter)

      payload = consume!(Hashie::Mash.new, represent_with: Api::V1::StudentRepresenter)
      if @student.save && payload['course_membership_period_id']
        period = CourseMembership::Models::Period.find(payload['course_membership_period_id'])
        period_update_result = MoveStudent.call(student: @student, period: period)
        # re-check access to ensure the requesting user has permission to move student to the new period
        OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @student)
      end
    end

    if period_update_result && period_update_result.errors.any?
      render_api_errors(period_update_result.errors)
    elsif @student.errors.any?
      render_api_errors(@student.errors)
    else
      respond_with @student,
                   represent_with: Api::V1::StudentRepresenter,
                   responder: ResponderWithPutPatchDeleteContent
    end
  end

  api :DELETE, '/students/:student_id', 'Drops a student from their course'
  description <<-EOS
    Drops a student from their course.

    Possible error code: already_inactive

    #{json_schema(Api::V1::StudentRepresenter, include: :readable)}
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, @student)
    result = CourseMembership::InactivateStudent.call(student: @student)

    render_api_errors(result.errors) || respond_with(
      result.outputs.student,
      represent_with: Api::V1::StudentRepresenter,
      responder: ResponderWithPutPatchDeleteContent
    )
  end

  api :PUT, '/students/:student_id/restore', 'Restores a student to their course'
  description <<-EOS
    Restores a student to their course.

    Possible error code: already_active
  EOS
  def restore
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, @student)
    result = CourseMembership::ActivateStudent.call(student: @student)

    render_api_errors(result.errors) || respond_with(
      result.outputs.student,
      represent_with: Api::V1::StudentRepresenter,
      responder: ResponderWithPutPatchDeleteContent
    )
  end

  protected

  def get_student
    @student = CourseMembership::Models::Student.find(params[:id])
  end

  def get_course_student
    @course = CourseProfile::Models::Course.find(params[:course_id])
    result = ChooseCourseRole.call(user: current_human_user,
                                   course: @course,
                                   role_id: params[:role_id],
                                   allowed_role_types: :student)
    raise(SecurityTransgression, result.errors.map(&:message).to_sentence) if result.errors.any?
    @student = result.outputs.role.student
  end

end
