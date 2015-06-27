class Api::V1::StudentsController < Api::V1::ApiController

  before_filter :get_student, only: [:update, :destroy]

  resource_description do
    api_versions "v1"
    short_description 'Represents a user in a course period'
    description <<-EOS
      Students are users who are part of a course period.
      Teachers are allowed to create and delete students and move them between periods.
    EOS
  end

  api :GET, '/courses/:course_id/students', 'Returns all students in the given course'
  description <<-EOS
    Returns all students in the given course.
    #{json_schema(Api::V1::StudentsRepresenter, include: :readable)}
  EOS
  def index
    course = Entity::Course.find(params[:course_id])
    OSU::AccessPolicy.require_action_allowed!(:roster, current_api_user, course)

    roster = GetStudentRoster[course: course]
    respond_with(roster, represent_with: Api::V1::StudentsRepresenter)
  end

  api :POST, '/courses/:course_id/students', 'Creates a new user and adds them to the period'
  description <<-EOS
    Creates a new user and adds them to the given course period.
    #{json_schema(Api::V1::NewStudentRepresenter, include: :writeable)}
  EOS
  def create
    # OpenStax::Api#standard_(update|create) require an ActiveRecord model, which we don't have
    # Substitue a Hashie::Mash to read the JSON encoded body
    CourseMembership::Models::Student.transaction do
      @payload = consume!(Hashie::Mash.new, represent_with: Api::V1::NewStudentRepresenter)
      period = CourseMembership::Models::Period.find(@payload.delete 'course_membership_period_id')
      args = @payload.to_hash.symbolize_keys.merge(period: period)
      @result = CreateStudent.call(args)
      @student = @result.outputs[:student]
      OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, @student)
      raise SecurityTransgression \
        unless @student.period.entity_course_id.to_s == params[:course_id].to_s
    end

    if @result.errors.any?
      render json: { errors: @result.errors }, status: :conflict
    else
      respond_with @payload.merge(@student.attributes),
                   represent_with: Api::V1::NewStudentRepresenter,
                   location: api_student_url(@student)
    end
  end

  api :PATCH, '/students/:student_id', "Changes a student's information"
  description <<-EOS
    Changes a student's information.
    Currently, only the period can be modified.
    #{json_schema(Api::V1::StudentRepresenter, include: :writeable)}
  EOS
  def update
    standard_update(@student, Api::V1::StudentRepresenter)
  end

  api :DELETE, '/students/:student_id', 'Removes a student from their course'
  description <<-EOS
    Removes a student from their course.
  EOS
  def destroy
    standard_destroy(@student)
  end

  protected

  def get_student
    @student = CourseMembership::Models::Student.find(params[:id])
  end

end
