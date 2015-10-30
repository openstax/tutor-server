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
    #{json_schema(Api::V1::TaskRepresenter, include: :readable)}
  EOS
  def show
    OSU::AccessPolicy.require_action_allowed!(
      :show, current_human_user, Tasks::Models::ConceptCoachTask
    )

    roles = Role::GetUserRoles[current_human_user, :student]
    ecosystem_id_role_map = roles.each_with_object({}) do |role, hash|
      ecosystem_id = role.student.course.course_ecosystems.first.content_ecosystem_id
      hash[ecosystem_id] ||= []
      hash[ecosystem_id] << role
    end

    page_models = Content::Models::Page
      .joins(:book)
      .where(book: { uuid: params[:cnx_book_id], content_ecosystem_id: ecosystem_id_role_map.keys },
             uuid: params[:cnx_page_id])

    # TODO: Handle ambiguous page (size > 1)?
    page_model = page_models.order(:created_at).last

    return head(:unprocessable_entity) if page_model.blank?

    page = Content::Page.new(strategy: page_model.wrap)
    ecosystem_id = page.ecosystem.id

    roles = ecosystem_id_role_map[ecosystem_id]

    # TODO: Handle ambiguous role (size > 1)?
    role = roles.first

    task = GetConceptCoach[role: role, page: page].task

    respond_with task, represent_with: Api::V1::TaskRepresenter
  end

end
