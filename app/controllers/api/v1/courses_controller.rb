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
    courses = Domain::ListCourses.call(user: current_human_user, with: :roles)
                                 .outputs.courses
    respond_with courses, represent_with: Api::V1::CoursesRepresenter
  end

  api :GET, '/courses/:course_id/readings', 'Returns a course\'s readings'
  description <<-EOS
    Returns a hierarchical listing of a course's readings.  A course is currently limited to
    only one book.  Inside each book there can be units or chapters (parts), and eventually
    parts (normally chapters) contain pages that have no children.

    #{json_schema(Api::V1::BookTocRepresenter, include: :readable)}
  EOS
  def readings
    course = Entity::Models::Course.find(params[:id])
    # OSU::AccessPolicy.require_action_allowed!(:readings, current_api_user, course)

    # For the moment, we're assuming just one book per course
    books = CourseContent::GetCourseBooks.call(course: course).outputs.books
    raise NotYetImplemented if books.count > 1

    toc = Content::VisitBook[book: books.first, visitor_names: :toc]
    respond_with toc, represent_with: Api::V1::BookTocRepresenter
  end

  api :GET, '/courses/:course_id/plans', 'Returns a course\'s plans'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanSearchRepresenter, include: :writeable)}
  EOS
  def plans
    course = Entity::Models::Course.find(params[:id])
    # OSU::AccessPolicy.require_action_allowed!(:task_plans, current_api_user, course)

    out = GetCourseTaskPlans.call(course: course).outputs
    respond_with out, represent_with: Api::V1::TaskPlanSearchRepresenter
  end

  api :GET, '/courses/:course_id/tasks', 'Gets all course tasks assigned to the role holder making the request'
  description <<-EOS
    As a temporary patch to make this route available, this route currently returns exactly the same
    thing as /api/user/tasks.  Once the backend does more work to make routes role-aware, we'll update
    this endpoint to actually do what the description says.
    #{json_schema(Api::V1::TaskSearchRepresenter, include: :readable)}
  EOS
  def tasks
    # TODO actually make this URL role-aware and return the tasks for the role
    # in the specified course; for now this is just returning what /api/user/tasks
    # returns and is ignore
    course = Entity::Models::Course.find(params[:id])
    # OSU::AccessPolicy.require_action_allowed!(:read_tasks, current_api_user, course)
    tasks = Domain::GetCourseUserTasks[course: course, user: current_human_user]

    output = Hashie::Mash.new({'items' => tasks})
    # outputs = SearchTasks.call(q: "user_id:#{current_human_user.id}").outputs
    respond_with output, represent_with: Api::V1::TaskSearchRepresenter
  end

  api :GET, '/courses/:course_id/events', 'Gets all events for a given course'
  description <<-EOS
    #{json_schema(Api::V1::CourseEventsRepresenter, include: :readable)}
  EOS
  def events
    course = Entity::Models::Course.find(params[:id])
    outputs = GetUserCourseEvents.call(user: current_human_user, course: course).outputs
    respond_with outputs, represent_with: Api::V1::CourseEventsRepresenter
  end

  api :GET, '/courses/:course_id/practice', 'TODO get rid of this documentation'
  description 'TODO somehow get rid of this API documentation, not desired'
  def practice
    request.post? ? practice_post : practice_get
  end

  api :POST, '/courses/:course_id/practice(/role/:role_id)', 'Starts a new practice widget'
  description 'TBD'
  def practice_post
    entity_task = Domain::ResetPracticeWidget[role: get_practice_role, condition: :fake]
    respond_with entity_task.task, represent_with: Api::V1::TaskRepresenter, location: nil
  end

  api :GET, '/courses/:course_id/practice(/role/:role_id)', 'Gets the most recent practice widget'
  def practice_get
    task = Domain::GetPracticeWidget.call(role: get_practice_role).outputs.task

    task.nil? ?
      head(:not_found) :
      respond_with(task.task, represent_with: Api::V1::TaskRepresenter)
  end

  protected

  def get_practice_role
    potential_roles = Domain::GetUserCourseRoles.call(course: Entity::Models::Course.find(params[:id]),
                                                      user: current_human_user.entity_user,
                                                      types: [:student]).outputs.roles

    raise(SecurityTransgression, "The caller is not a student in this course") if potential_roles.empty?

    practice_role = nil

    if params[:role_id]
      practice_role = Entity::Models::Role.find(params[:role_id])
      raise(SecurityTransgression, "The caller does not have the specified role") unless potential_roles.include?(practice_role)
    else
      raise(IllegalState, "The role must be specified because there is more than one student role available") if potential_roles.size > 1
      practice_role = potential_roles.first
    end

    practice_role
  end

end
