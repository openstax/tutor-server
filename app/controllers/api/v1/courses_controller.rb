class Api::V1::CoursesController < Api::V1::ApiController

  CREATE_REQUIRED_ATTRIBUTES = [
    :name, :is_preview, :num_sections, :catalog_offering_id
  ]

  before_filter :get_course, only: [:show, :update, :dashboard, :cc_dashboard, :roster, :clone]
  before_filter :error_if_student_and_needs_to_pay, only: [:dashboard]

  resource_description do
    api_versions "v1"
    short_description 'Represents a course in the system'
    description <<-EOS
      Course description to be written...
    EOS
  end

  api :GET, '/courses', 'Returns courses'
  description <<-EOS
    Returns courses in the system, and the user who requested them is shown
    their own roles related to their courses
    #{json_schema(Api::V1::CoursesRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(
      :index, current_api_user, CourseProfile::Models::Course
    )

    course_infos = CollectCourseInfo[user: current_human_user]

    respond_with course_infos, represent_with: Api::V1::CoursesRepresenter
  end

  api :POST, '/courses', 'Creates a new course'
  description <<-EOS
    Creates a new course for the current (verified teacher) human user
    #{json_schema(Api::V1::CourseRepresenter, include: :writeable)}
  EOS
  def create
    OSU::AccessPolicy.require_action_allowed!(
      :create, current_api_user, CourseProfile::Models::Course
    )

    attributes = consumed(Api::V1::CourseRepresenter)

    errors = CREATE_REQUIRED_ATTRIBUTES.reject{ |sym| attributes.has_key?(sym) }.map do |sym|
      { code: :missing_attribute, message: "The #{sym} attribute must be provided" }
    end
    return render_api_errors(errors) unless errors.empty?

    render_api_errors(code: :invalid_term, message: 'The given course term is invalid') and return \
      if attributes[:term].present? && !TermYear::VISIBLE_TERMS.include?(attributes[:term].to_sym)

    catalog_offering = Catalog::Models::Offering.find(attributes[:catalog_offering_id])
    OSU::AccessPolicy.require_action_allowed!(:create_course, current_api_user, catalog_offering)

    result = CreateOrClaimCourse.call(
      attributes.except(:catalog_offering_id).merge(
        teacher: current_human_user,
        catalog_offering: catalog_offering
      )
    )

    return render_api_errors(result.errors) unless result.errors.empty?

    respond_with collect_course_info(course: result.outputs.course),
                 represent_with: Api::V1::CourseRepresenter,
                 location: nil
  end

  api :GET, '/courses/:id', 'Returns information about a specific course, including periods'
  description <<-EOS
    Returns information about a specific course, including periods and roles
    #{json_schema(Api::V1::CourseRepresenter, include: :readable)}
  EOS
  def show
    OSU::AccessPolicy.require_action_allowed!(:read, current_api_user, @course)

    respond_with collect_course_info(course: @course), represent_with: Api::V1::CourseRepresenter
  end

  api :PATCH, '/courses/:id', 'Update course details'
  description <<-EOS
    Update course details and return information about the updated course
    Possible error codes:
      - invalid_time_zone

    #{json_schema(Api::V1::CourseRepresenter, include: :readable)}
  EOS
  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @course)
    result = UpdateCourse.call(params[:id], **consumed(Api::V1::CourseRepresenter))

    render_api_errors(result.errors) || respond_with(
      collect_course_info(course: @course.reload),
      represent_with: Api::V1::CourseRepresenter,
      location: nil,
      responder: ResponderWithPutPatchDeleteContent
    )
  end

  api :GET, '/courses/:id/dashboard',
            'Gets dashboard information for a given non-CC course, ' +
            'filtered by optional start_at and end_at params. ' +
            'Any time_zone information in the given dates is ignored ' +
            'and they are assumed to be in the course\'s time_zone.'
  description <<-EOS
    Possible error codes:
      - cc_course

    #{json_schema(Api::V1::Courses::DashboardRepresenter, include: :readable)}
  EOS
  def dashboard
    start_at = DateTimeUtilities.from_s(params[:start_at])
    start_at_ntz = DateTimeUtilities.remove_tz(start_at)
    end_at = DateTimeUtilities.from_s(params[:end_at])
    end_at_ntz = DateTimeUtilities.remove_tz(end_at)

    result = GetTpDashboard.call(course: @course,
                                 role: get_course_role(course: @course),
                                 start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz)

    render_api_errors(result.errors) || respond_with(
      result.outputs, represent_with: Api::V1::Courses::DashboardRepresenter,
                      user_options: { exclude_job_info: true }
    )
  end

  api :GET, '/courses/:id/cc/dashboard', 'Gets dashboard information for a given CC course.'
  description <<-EOS
    Possible error codes:
      - non_cc_course

    #{json_schema(Api::V1::Courses::Cc::DashboardRepresenter, include: :readable)}
  EOS
  def cc_dashboard
    result = GetCcDashboard.call(course: @course, role: get_course_role(course: @course))

    render_api_errors(result.errors) || respond_with(
      result.outputs, represent_with: Api::V1::Courses::Cc::DashboardRepresenter
    )
  end

  api :GET, '/courses/:id/roster', 'Returns the roster for a given course'
  description <<-EOS
    Returns the roster for a given course
    #{json_schema(Api::V1::RosterRepresenter, include: :readable)}
  EOS
  def roster
    OSU::AccessPolicy.require_action_allowed!(:roster, current_api_user, @course)

    roster = GetCourseRoster[course: @course]

    respond_with(roster, represent_with: Api::V1::RosterRepresenter)
  end

  api :POST, '/courses/:id/clone', 'Clones the course with the given ID'
  description <<-EOS
    Creates a copy of the course with the given ID
    All JSON attributes in the schema are optional
    They will default to the given course's attributes if ommitted
    #{json_schema(Api::V1::CourseCloneRepresenter, include: :writeable)}
  EOS
  def clone
    OSU::AccessPolicy.require_action_allowed!(:clone, current_api_user, @course)

    attributes = consumed(Api::V1::CourseCloneRepresenter)
      .slice(:copy_question_library, :name, :is_college, :term, :year, :num_sections, :time_zone,
             :default_open_time, :default_due_time, :estimated_student_count)
      .merge(course: @course, teacher_user: current_human_user)

    course = CloneCourse[attributes]

    respond_with collect_course_info(course: course),
                 represent_with: Api::V1::CourseRepresenter,
                 location: nil
  end

  api :POST, '/course_dates', 'Returns a mapping of course UUIDs to start/end dates'
  description <<-EOS
    Returns a mapping of course UUIDs to start/end dates
    The request body must contain only an array of course UUIDs:
    <pre class="code">{
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[0-9a-f]{8}-[0-9a-f]{4}-[4][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
      }
    }</pre>

    The response body will contain a mapping from course UUIDs to start and end dates:

    <pre class="code">{
      "type": "object",
      "patternProperties": {
        "^[0-9a-f]{8}-[0-9a-f]{4}-[4][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$": {
          "type": "object",
          "properties": {
            "starts_at": {
              "type": "string",
              "format": "date-time"
            },
            "ends_at": {
              "type": "string",
              "format": "date-time"
            }
          },
          "required": [ "starts_at", "ends_at" ],
          "additionalProperties": false
        }
      },
      "additionalProperties": false
    }</pre>
  EOS
  def dates
    uuid_array = begin
      JSON.parse request.body.read
    rescue JSON::ParserError
      return bad_request('Request body is invalid JSON')
    end
    return bad_request('Request body must contain only a JSON array') unless uuid_array.is_a?(Array)
    return bad_request('Request body array elements must all be UUID strings') \
      unless uuid_array.all? { |uuid| uuid.is_a? String }

    course_dates_map = {}
    CourseProfile::Models::Course.where(uuid: uuid_array)
                                 .pluck(:uuid, :starts_at, :ends_at)
                                 .each do |uuid, starts_at, ends_at|
      course_dates_map[uuid] = {
        starts_at: DateTimeUtilities.to_api_s(starts_at),
        ends_at: DateTimeUtilities.to_api_s(ends_at)
      }
    end

    render json: course_dates_map
  end

  api :PUT, '/courses/:id/roles/:role_id/become', 'Become the specified role in the course'
  description <<-EOS
    Become the specified role in the specified course

    The role must belong to the calling user and must be in the specified course
  EOS
  def become
    OSU::AccessPolicy.require_action_allowed!(:become, current_human_user, @role)

    session[:roles] ||= {}
    session[:roles][@course.id] = @role.id
  end

  protected

  def get_role
    @role = Entity::Role.find(params[:id])
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:id])
  end

  def collect_course_info(course:)
    CollectCourseInfo[courses: course, user: current_human_user].first
  end

  def get_course_role(course:)
    result = ChooseCourseRole.call(
      user: current_human_user, course: course, role: current_role(course)
    )
    errors = result.errors
    raise(SecurityTransgression, :invalid_role) unless errors.empty?
    result.outputs.role
  end

  def bad_request(message)
    render json: { errors: [ { message: message } ] }, status: :bad_request
  end
end
