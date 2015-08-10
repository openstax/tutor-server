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
    courses_info = CollectCourseInfo[user: current_human_user.entity_user,
                                     with: [:roles, :periods]]
    respond_with courses_info, represent_with: Api::V1::CoursesRepresenter
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
    course_info = CollectCourseInfo[course: course,
                                    user: current_human_user.entity_user,
                                    with: [:roles, :periods]].first
    respond_with course_info, represent_with: Api::V1::CourseRepresenter
  end

  api :GET, '/courses/:course_id/readings', 'Returns a course\'s readings'
  description <<-EOS
    Returns a hierarchical listing of a course's readings.  A course is currently limited to
    only one book.  Inside each book there can be units or chapters (parts), and eventually
    parts (normally chapters) contain pages that have no children.

    #{json_schema(Api::V1::BookTocRepresenter, include: :readable)}
  EOS
  def readings
    course = Entity::Course.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:readings, current_api_user, course)

    # For the moment, we're assuming just one ecosystem per course
    ecosystems = CourseContent::GetCourseEcosystems.call(course: course).outputs.ecosystems
    books = ecosystems.collect{ |es| es.books }.flatten
    raise NotYetImplemented if books.count > 1

    respond_with books.collect{ |bk| bk.toc }, represent_with: Api::V1::BookTocRepresenter
  end

  api :GET, '/courses/:course_id/exercises',
            "Returns a course\'s exercises, filtered by the page_ids param"
  description <<-EOS
    Returns a list of assignable exercises tagged with LO's matching the pages
    or book_parts with the given ID's.
    If no page_ids or book_part_ids are specified, returns an empty array.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def exercises
    course = Entity::Course.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, course)

    ecosystem = GetCourseEcosystem[course: course]
    pages = ecosystem.pages_by_ids(params[:page_ids])
    exercises = ecosystem.homework_core_pools(pages: pages).collect{ |pl| pl.exercises }.flatten

    respond_with exercises, represent_with: Api::V1::ExerciseSearchRepresenter
  end

  api :GET, '/courses/:course_id/tasks', 'Gets all course tasks assigned to the role holder making the request'
  description <<-EOS
    #{json_schema(Api::V1::TaskSearchRepresenter, include: :readable)}
  EOS
  def tasks
    # No authorization is necessary because if the user isn't authorized, they'll just get
    # back an empty list of tasks
    course = Entity::Course.find(params[:id])
    tasks = GetCourseUserTasks[course: course, user: current_human_user.entity_user]
    output = Hashie::Mash.new('items' => tasks.collect{|t| t.task})
    respond_with output, represent_with: Api::V1::TaskSearchRepresenter
  end

  api :GET, '/courses/:course_id/dashboard(/role/:role_id)', 'Gets dashboard information for a given course'
  description <<-EOS
    #{json_schema(Api::V1::Courses::DashboardRepresenter, include: :readable)}
  EOS
  def dashboard
    course = Entity::Course.find(params[:id])
    data = Api::V1::Courses::Dashboard.call(
             course: course,
             role: get_course_role
           ).outputs
    respond_with data, represent_with: Api::V1::Courses::DashboardRepresenter
  end

  protected
  def get_course_role(types: :any)
    result = ChooseCourseRole.call(user: current_human_user.entity_user,
                                   course: Entity::Course.find(params[:id]),
                                   allowed_role_type: types,
                                   role_id: params[:role_id])
    if result.errors.any?
      raise(IllegalState, result.errors.map(&:message).to_sentence)
    end
    result.outputs.role
  end
end
