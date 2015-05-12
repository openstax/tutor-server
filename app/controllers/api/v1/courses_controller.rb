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
    courses = ListCourses.call(user: current_human_user.entity_user,
                               with: :roles).outputs.courses
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
    course = Entity::Course.find(params[:id])

    # For the moment, we're assuming just one book per course
    books = CourseContent::GetCourseBooks.call(course: course).outputs.books
    raise NotYetImplemented if books.count > 1

    toc = Content::VisitBook[book: books.first, visitor_names: :toc]
    # Return [toc] as a list so that in the future we may have toc from more
    # than one book
    respond_with [toc], represent_with: Api::V1::BookTocRepresenter
  end

  api :GET, '/courses/:course_id/exercises',
            "Returns a course\'s exercises, filtered by the page_ids param or the book_part_ids params"
  description <<-EOS
    Returns a list of exercises tagged with LO's matching the pages
    or book_parts with the given ID's.
    If no page_ids or book_part_ids are specified, returns an empty array.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def exercises
    course = Entity::Course.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, course)

    los = Content::GetLos[params]
    outputs = SearchLocalExercises.call(tag: los, match_count: 1).outputs

    respond_with outputs, represent_with: Api::V1::ExerciseSearchRepresenter
  end

  api :GET, '/courses/:course_id/plans', 'Returns a course\'s plans'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanSearchRepresenter, include: :writeable)}
  EOS
  def plans
    course = Entity::Course.find(params[:id])
    # OSU::AccessPolicy.require_action_allowed!(:task_plans, current_api_user, course)

    out = GetCourseTaskPlans.call(course: course).outputs
    respond_with out, represent_with: Api::V1::TaskPlanSearchRepresenter
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

  api :GET, '/courses/:course_id/events(/role/:role_id)', 'Gets all events for a given course'
  description <<-EOS
    #{json_schema(Api::V1::CourseEventsRepresenter, include: :readable)}
  EOS
  def events
    course = Entity::Course.find(params[:id])
    result = GetRoleCourseEvents.call(course: course, role: get_course_role(types: :any))
    respond_with result.outputs, represent_with: Api::V1::CourseEventsRepresenter
  end

  api :GET, '/courses/:course_id/dashboard(/role/:role_id)', 'Gets dashboard information for a given course'
  description <<-EOS
    #{json_schema(Api::V1::Courses::DashboardRepresenter, include: :readable)}
  EOS
  def dashboard
    course = Entity::Course.find(params[:id])
    data = Api::V1::Courses::Dashboard.call(
             course: course,
             role: get_course_role(types: :any)
           ).outputs
    respond_with data, represent_with: Api::V1::Courses::DashboardRepresenter
  end

  api :GET, '/courses/:id/stats(/role/:role_id)', 'Returns course stats for Learning Guide'
  description <<-EOS
    #{json_schema(Api::V1::CourseStatsRepresenter, include: :readable)}
  EOS
  def stats
    course = Entity::Course.find(params[:id])
    role = ChooseCourseRole[course: course,
                            user: current_human_user.entity_user,
                            allowed_role_type: :student,
                            role_id: params[:role_id]]
    course_stats = GetCourseStats[role: role, course: course]
    respond_with course_stats, represent_with: Api::V1::CourseStatsRepresenter
  end

  api nil, nil, nil
  description nil
  def practice
    request.post? ? practice_post : practice_get
  end

  api :POST, '/courses/:course_id/practice(/role/:role_id)',
             'Starts a new practice widget'
  description <<-EOS
    #{json_schema(Api::V1::PracticeRepresenter, include: :writeable)}
  EOS
  def practice_post
    practice = OpenStruct.new
    consume!(practice, represent_with: Api::V1::PracticeRepresenter)

    entity_task = ResetPracticeWidget[
      role: get_practice_role, condition: :local,
      page_ids: practice.page_ids, book_part_ids: practice.book_part_ids
    ]
    respond_with entity_task.task, represent_with: Api::V1::TaskRepresenter, location: nil
  end

  api :GET, '/courses/:course_id/practice(/role/:role_id)',
            'Gets the most recent practice widget'
  def practice_get
    task = GetPracticeWidget[role: get_practice_role]

    task.nil? ?
      head(:not_found) : respond_with(task.task, represent_with: Api::V1::TaskRepresenter)
  end

  api :GET, '/courses/:course_id/performance(/role/:role_id)', 'Returns performance book for the user'
  description <<-EOS
    #{json_schema(Api::V1::PerformanceBookRepresenter, include: :readable)}
  EOS
  def performance
    course = Entity::Course.find(params[:id])
    role = ChooseCourseRole[course: course, user: current_human_user.entity_user, role_id: params[:role_id]]
    pbook = Tasks::GetPerformanceBook[course: course, role: role]

    respond_with(Hashie::Mash.new(pbook), represent_with: Api::V1::PerformanceBookRepresenter)
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

  def get_practice_role
    get_course_role(types: :student)
  end

end
