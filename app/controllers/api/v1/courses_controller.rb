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
    Returns a list of assignable exercises tagged with LO's matching the pages
    or book_parts with the given ID's.
    If no page_ids or book_part_ids are specified, returns an empty array.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def exercises
    course = Entity::Course.find(params[:id])
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, course)

    lo_outputs = Content::GetLos.call(params).outputs
    tags = lo_outputs.los + lo_outputs.aplos

    review_exercises = Content::Routines::SearchExercises[tag: 'ost-chapter-review']
    review_exercise_ids = review_exercises.pluck(:id)
    review_exercise_relation = Content::Models::Exercise.where(id: review_exercise_ids)
    search_outputs = SearchLocalExercises.call(relation: review_exercise_relation,
                                               tag: tags,
                                               match_count: 1).outputs

    respond_with search_outputs, represent_with: Api::V1::ExerciseSearchRepresenter
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

  api :POST, '/courses/:course_id/performance/export',
             'Begins the export of the performance report for authorized teachers'
  description <<-EOS
    202 if the role is a teacher of a course
      -- The export background job will be started
  EOS
  def performance_export
    course = Entity::Course.find(params[:id])

    OSU::AccessPolicy.require_action_allowed!(:export, current_api_user, course)

    job_id = Tasks::ExportPerformanceReport.perform_later(course: course,
                                                          role: get_course_role)

    render json: { job: api_job_path(job_id) }, status: :accepted
  end

  api :GET, '/courses/:course_id/performance/exports',
            'Gets the export history of the performance report for authorized teachers'
  description <<-EOS
    #{json_schema(Api::V1::PerformanceReportExportsRepresenter, include: :readable)}
  EOS
  def performance_exports
    course = Entity::Course.find(params[:id])

    OSU::AccessPolicy.require_action_allowed!(:export, current_api_user, course)

    exports = Tasks::GetPerformanceReportExports[course: course, role: get_course_role]

    respond_with exports, represent_with: Api::V1::PerformanceReportExportsRepresenter
  end

  api :GET, '/courses/:course_id/performance(/role/:role_id)', 'Returns performance report for the user'
  description <<-EOS
    #{json_schema(Api::V1::PerformanceReportRepresenter, include: :readable)}
  EOS
  def performance
    course = Entity::Course.find(params[:id])
    preport = Tasks::GetPerformanceReport[course: course, role: get_course_role]

    respond_with(preport, represent_with: Api::V1::PerformanceReportRepresenter)
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
