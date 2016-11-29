class Api::V1::Cc::TasksController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a concept coach task'
    description <<-EOS
      see `/api/tasks`
    EOS
  end

  ###############################################################
  # show
  ###############################################################

  api :GET, 'cc/tasks/:cnx_book_id/:cnx_page_id',
            'Gets the Concept Coach Task for the given CNX page'
  description <<-EOS
    The `cnx_book_id` and `cnx_page_id` should not contain version information.

    Possible error codes:
      invalid_book
      invalid_page
      not_a_cc_student
      page_has_no_exercises
    #{json_schema(Api::V1::TaskRepresenter, include: :readable)}
  EOS
  def show
    OSU::AccessPolicy.require_action_allowed!(
      :show, current_human_user, Tasks::Models::ConceptCoachTask
    )

    result = GetConceptCoach.call(user: current_human_user,
                                  book_uuid: params[:cnx_book_id],
                                  page_uuid: params[:cnx_page_id])

    if result.errors.any?
      json_hash = { errors: result.errors, valid_books: result.outputs.valid_book_urls }
      render json: json_hash, status: :unprocessable_entity
    else
      respond_with result.outputs.task, represent_with: Api::V1::TaskRepresenter
    end
  end

  ###############################################################
  # stats
  ###############################################################

  api :GET, 'cc/tasks/:course_id/:cnx_page_id/stats',
            'Gets the Concept Coach Task stats for the given CNX page'
  description <<-EOS
    The `cnx_page_id` should not contain version information.

    #{json_schema(Api::V1::ConceptCoachStatsRepresenter, include: :readable)}
  EOS
  def stats
    course = CourseProfile::Models::Course.find(params[:course_id])
    OSU::AccessPolicy.require_action_allowed!(:stats, current_human_user, course)

    ecosystem_id = GetCourseEcosystem[course: course].id
    page_title = Content::Models::Page.joins(:book)
                                      .where(book: {content_ecosystem_id: ecosystem_id},
                                             uuid: params[:cnx_page_id])
                                      .pluck(:title).first
    student_role_ids = CourseMembership::GetCourseRoles[course: course, types: :student].map(&:id)
    tasks = Tasks::Models::Task.joins(concept_coach_task: :page)
                               .where(concept_coach_task: { entity_role_id: student_role_ids,
                                                            page: { uuid: params[:cnx_page_id] } })

    cc_stats = Hashie::Mash.new(title: page_title, stats: CalculateTaskStats[tasks: tasks])

    respond_with cc_stats, represent_with: Api::V1::ConceptCoachStatsRepresenter
  end

end
