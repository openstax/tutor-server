class Api::V1::CoursesController < Api::V1::ApiController

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
    OSU::AccessPolicy.require_action_allowed!(:index, current_api_user, Entity::Course)
    course_infos = CollectCourseInfo[user: current_human_user,
                                     with: [:roles, :periods, :ecosystem]]
    respond_with course_infos, represent_with: Api::V1::CoursesRepresenter
  end

  api :GET, '/courses/:course_id/roster', 'Returns the roster for a given course'
  description <<-EOS
    Returns the roster for a given course
    #{json_schema(Api::V1::RosterRepresenter, include: :readable)}
  EOS
  def roster
    course = Entity::Course.find(params[:course_id])
    OSU::AccessPolicy.require_action_allowed!(:roster, current_api_user, course)

    roster = GetCourseRoster[course: course]
    respond_with(roster, represent_with: Api::V1::RosterRepresenter)
  end


  api :GET, '/courses/:course_id', 'Returns information about a specific course, including periods'
  description <<-EOS
    Returns information about a specific course, including periods and roles
    #{json_schema(Api::V1::CourseRepresenter, include: :readable)}
  EOS
  def show
    course = Entity::Course.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:read, current_api_user, course)

    # Use CollectCourseInfo instead of just representing the entity course so
    # we can gather extra information
    course_info = CollectCourseInfo[courses: course,
                                    user: current_human_user,
                                    with: [:roles, :periods, :ecosystem]].first
    respond_with course_info, represent_with: Api::V1::CourseRepresenter
  end

  api :PATCH, '/courses/:course_id', 'Update course details'
  description <<-EOS
    Update course details and return information about the updated course
    #{json_schema(Api::V1::CourseRepresenter, include: :readable)}
  EOS
  def update
    course = Entity::Course.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, course)

    UpdateCourse.call(params[:id], { name: params[:course][:name] })

    # Use CollectCourseInfo instead of just representing the entity course so
    # we can gather extra information
    course_info = CollectCourseInfo[courses: course,
                                    user: current_human_user,
                                    with: [:roles, :periods, :ecosystem]].first
    respond_with course_info, represent_with: Api::V1::CourseRepresenter,
                              location: nil,
                              responder: ResponderWithPutContent
  end

  api :GET, '/courses/:course_id/tasks', 'Gets all course tasks assigned to the role holder making the request'
  description <<-EOS
    #{json_schema(Api::V1::TaskSearchRepresenter, include: :readable)}
  EOS
  def tasks
    # No authorization is necessary because if the user isn't authorized, they'll just get
    # back an empty list of tasks
    course = Entity::Course.find(params[:id])
    tasks = GetCourseUserTasks[course: course, user: current_human_user]
    output = Hashie::Mash.new('items' => tasks.collect{|t| t.task})
    respond_with output, represent_with: Api::V1::TaskSearchRepresenter
  end

  api :GET, '/courses/:course_id/dashboard(/role/:role_id)',
            'Gets dashboard information for a given non-CC course'
  description <<-EOS
    Possible error codes:
      - cc_course

    #{json_schema(Api::V1::Courses::DashboardRepresenter, include: :readable)}
  EOS
  def dashboard
    course = Entity::Course.find(params[:id])
    result = GetNonCcDashboard.call(course: course, role: get_course_role)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs, represent_with: Api::V1::Courses::DashboardRepresenter
    end
  end

  api :GET, '/courses/:course_id/cc/dashboard(/role/:role_id)',
            'Gets dashboard information for a given CC course'
  description <<-EOS
    Possible error codes:
      - non_cc_course

    #{json_schema(Api::V1::Courses::Cc::DashboardRepresenter, include: :readable)}
  EOS
  def cc_dashboard
    course = Entity::Course.find(params[:id])
    result = GetCcDashboard.call(course: course, role: get_course_role)

    if result.errors.any?
      render_api_errors(result.errors)
    else
      respond_with result.outputs, represent_with: Api::V1::Courses::Cc::DashboardRepresenter
    end
  end

  protected
  def get_course_role(types: :any)
    result = ChooseCourseRole.call(user: current_human_user,
                                   course: Entity::Course.find(params[:id]),
                                   allowed_role_type: types,
                                   role_id: params[:role_id])
    if result.errors.any?
      raise(SecurityTransgression, result.errors.map(&:message).to_sentence)
    end
    result.outputs.role
  end
end
