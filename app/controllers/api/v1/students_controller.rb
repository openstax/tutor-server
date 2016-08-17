class Api::V1::StudentsController < Api::V1::ApiController

  before_filter :get_student, only: [:update, :destroy, :undrop]

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
    @student = get_course_student
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
    @period_update_result = nil
    @student.with_lock do
      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @student)
      payload = consume!(@student, represent_with: Api::V1::StudentRepresenter)
      consume!(@student, represent_with: Api::V1::StudentTeacherUpdateRepresenter)
      if @student.save && payload['course_membership_period_id']
        period = CourseMembership::Models::Period.find(payload['course_membership_period_id'])
        @period_update_result = MoveStudent.call(student: @student, period: period)
      end
    end

    if @period_update_result && @period_update_result.errors.any?
      render_api_errors(@period_update_result.errors)
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

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs.student,
                   represent_with: Api::V1::StudentRepresenter,
                   responder: ResponderWithPutPatchDeleteContent
    end
  end

  api :PUT, '/students/:student_id/undrop', 'Undrops a student from their course'
  description <<-EOS
    Undrops a student from their course.

    Possible error code: already_active
  EOS
  def undrop
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, @student)
    result = CourseMembership::ActivateStudent.call(student: @student)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs.student,
                   represent_with: Api::V1::StudentRepresenter,
                   responder: ResponderWithPutPatchDeleteContent
    end
  end

  protected

  def get_student
    @student = CourseMembership::Models::Student.with_deleted.find(params[:id])
  end

  def get_course_student
    result = ChooseCourseRole.call(user: current_human_user,
                                   course: Entity::Course.find(params[:course_id]),
                                   allowed_role_type: :student)
    raise(SecurityTransgression, result.errors.map(&:message).to_sentence) if result.errors.any?
    result.outputs.role.student
  end

end
