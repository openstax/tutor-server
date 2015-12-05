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

  # TEMPORARILY REMOVED THIS ABILITY FOR END USERS TO ADD STUDENTS, AS THE WORKFLOW IS
  # MORE COMPLEX THAN ORIGINALLY THOUGHT (UX NEEDS TO STUDY IT).  ONLY MECHANISM FOR
  # ADDING STUDENTS WILL BE THROUGH THE ADMIN CONSOLE
  #
  # api :POST, '/courses/:course_id/students', 'Creates a new user and adds them to the period'
  # description <<-EOS
  #   Creates a new user and adds them to the given course period.
  #   #{json_schema(Api::V1::NewStudentRepresenter, include: :writeable)}
  # EOS
  # def create
  #   # OpenStax::Api#standard_(update|create) require an ActiveRecord model, which we don't have
  #   # Substitue a Hashie::Mash to read the JSON encoded body
  #   CourseMembership::Models::Student.transaction do
  #     @payload = consume!(Hashie::Mash.new, represent_with: Api::V1::NewStudentRepresenter)
  #     period = CourseMembership::Models::Period.find(@payload.delete 'course_membership_period_id')
  #     args = @payload.to_hash.symbolize_keys.merge(period: period)
  #     @result = CreateStudent.call(args)
  #     @student = @result.outputs[:student]
  #     OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, @student)
  #     raise SecurityTransgression \
  #       unless @student.period.entity_course_id.to_s == params[:course_id].to_s
  #   end

  #   if @result.errors.any?
  #     render_api_errors(@result.errors)
  #   else
  #     respond_with @student,
  #                  represent_with: Api::V1::NewStudentRepresenter,
  #                  location: api_student_url(@student),
  #                  email: @payload.email
  #   end
  # end

  api :PATCH, '/students/:student_id', "Changes a student's information"
  description <<-EOS
    Changes a student's information.
    Currently, only the period can be modified.
    #{json_schema(Api::V1::StudentRepresenter, include: :writeable)}
  EOS
  def update
    @student.with_lock do
      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @student)
      payload = consume!(Hashie::Mash.new, represent_with: Api::V1::StudentRepresenter)
      period = CourseMembership::Models::Period.find(payload['course_membership_period_id'])
      @result = MoveStudent.call(student: @student, period: period)
      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @student)
    end

    if @result.errors.any?
      render_api_errors(@result.errors)
    else
      respond_with @result.outputs.student,
                   represent_with: Api::V1::StudentRepresenter,
                   responder: ResponderWithPutContent
    end
  end

  api :DELETE, '/students/:student_id', 'Drops a student from their course'
  description <<-EOS
    Drops a student from their course.

    Possible error code: already_inactive
  EOS
  def destroy
    OSU::AccessPolicy.require_action_allowed!(:destroy, current_api_user, @student)
    result = CourseMembership::InactivateStudent.call(student: @student)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      head :no_content
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
                   responder: ResponderWithPutContent
    end
  end

  protected

  def get_student
    @student = CourseMembership::Models::Student.find(params[:id])
  end

end
