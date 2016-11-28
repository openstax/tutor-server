class Api::V1::CoursesController < Api::V1::ApiController

  before_filter :get_course, only: [:show, :update, :dashboard, :cc_dashboard, :roster, :clone]

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

    course_infos = CollectCourseInfo[user: current_human_user,
                                     with: [:roles, :periods, :ecosystem, :students]]

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

    required_attributes = [:name, :term, :year, :num_sections, :is_college, :catalog_offering_id]

    errors = required_attributes.reject{ |sym| attributes.has_key?(sym) }.map do |sym|
      {code: :missing_attribute, message: "The #{sym} attribute must be provided"}
    end

    render_api_errors(errors) and return if errors.any?

    catalog_offering = Catalog::Models::Offering.find(attributes[:catalog_offering_id])

    OSU::AccessPolicy.require_action_allowed!(:create_course, current_api_user, catalog_offering)

    course_attributes = attributes.except(:catalog_offering_id)
                                  .merge(catalog_offering: catalog_offering, is_trial: false)

    course = CreateCourse[course_attributes]

    AddUserAsCourseTeacher[course: course, user: current_human_user]

    respond_with collect_course_info(course: course),
                 represent_with: Api::V1::CourseRepresenter,
                 location: nil
  end

  api :GET, '/courses/:course_id', 'Returns information about a specific course, including periods'
  description <<-EOS
    Returns information about a specific course, including periods and roles
    #{json_schema(Api::V1::CourseRepresenter, include: :readable)}
  EOS
  def show
    OSU::AccessPolicy.require_action_allowed!(:read, current_api_user, @course)

    respond_with collect_course_info(course: @course), represent_with: Api::V1::CourseRepresenter
  end

  api :PATCH, '/courses/:course_id', 'Update course details'
  description <<-EOS
    Update course details and return information about the updated course
    #{json_schema(Api::V1::CourseRepresenter, include: :readable)}
  EOS
  def update
    OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, @course)
    result = UpdateCourse.call(params[:id], **consumed(Api::V1::CourseRepresenter))

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with collect_course_info(course: @course),
                   represent_with: Api::V1::CourseRepresenter,
                   location: nil,
                   responder: ResponderWithPutPatchDeleteContent
    end
  end

  api :GET, '/courses/:course_id/dashboard(/role/:role_id)',
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

    result = GetNonCcDashboard.call(course: @course, role: get_course_role(course: @course),
                                    start_at_ntz: start_at_ntz, end_at_ntz: end_at_ntz)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs, represent_with: Api::V1::Courses::DashboardRepresenter
    end
  end

  api :GET, '/courses/:course_id/cc/dashboard(/role/:role_id)',
            'Gets dashboard information for a given CC course.'
  description <<-EOS
    Possible error codes:
      - non_cc_course

    #{json_schema(Api::V1::Courses::Cc::DashboardRepresenter, include: :readable)}
  EOS
  def cc_dashboard
    result = GetCcDashboard.call(course: @course, role: get_course_role(course: @course))

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs, represent_with: Api::V1::Courses::Cc::DashboardRepresenter
    end
  end

  api :GET, '/courses/:course_id/roster', 'Returns the roster for a given course'
  description <<-EOS
    Returns the roster for a given course
    #{json_schema(Api::V1::RosterRepresenter, include: :readable)}
  EOS
  def roster
    OSU::AccessPolicy.require_action_allowed!(:roster, current_api_user, @course)

    roster = GetCourseRoster[course: @course]

    respond_with(roster, represent_with: Api::V1::RosterRepresenter)
  end

  api :POST, '/courses/:course_id/clone', 'Clones the course with the given ID'
  description <<-EOS
    Creates a copy of the course with the given ID
    All JSON attributes in the schema are optional
    They will default to the given course's attributes if ommitted
    #{json_schema(Api::V1::CourseRepresenter, include: :writeable)}
  EOS
  def clone
    OSU::AccessPolicy.require_action_allowed!(:clone, current_api_user, @course)

    attributes = consumed(Api::V1::CourseCloneRepresenter)
      .slice(:copy_question_library, :name, :is_college, :term, :year, :num_sections, :time_zone,
             :default_open_time, :default_due_time)
      .merge(course: @course, teacher_user: current_human_user)

    course = CloneCourse[attributes]

    respond_with collect_course_info(course: course),
                 represent_with: Api::V1::CourseRepresenter,
                 location: nil
  end

  protected

  def get_course
    @course = CourseProfile::Models::Course.find(params[:id])
  end

  def collect_course_info(course:)
    CollectCourseInfo[courses: course,
                      user: current_human_user,
                      with: [:roles, :periods, :ecosystem, :students]].first
  end

  def get_course_role(course:, types: :any)
    result = ChooseCourseRole.call(user: current_human_user,
                                   course: course,
                                   allowed_role_type: types,
                                   role_id: params[:role_id])
    if result.errors.any?
      raise(SecurityTransgression, result.errors.map(&:message).to_sentence)
    end
    result.outputs.role
  end
end
