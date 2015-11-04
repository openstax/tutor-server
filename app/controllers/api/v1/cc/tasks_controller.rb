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
    #{json_schema(Api::V1::TaskRepresenter, include: :readable)}
  EOS
  def show
    OSU::AccessPolicy.require_action_allowed!(
      :show, current_human_user, Tasks::Models::ConceptCoachTask
    )

    result = GetConceptCoach.call(user: current_human_user,
                                  cnx_book_id: params[:cnx_book_id],
                                  cnx_page_id: params[:cnx_page_id])

    if result.errors.any?
      json_hash = { errors: result.errors, valid_books: result.outputs.valid_book_urls }
      render json: json_hash, status: :unprocessable_entity
    else
      respond_with result.outputs.task, represent_with: Api::V1::TaskRepresenter
    end
  end

end
