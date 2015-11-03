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

    roles = Role::GetUserRoles[current_human_user, :student]
    ecosystem_id_role_map = roles.each_with_object({}) do |role, hash|
      ecosystem_id = role.student.course.course_ecosystems.first.content_ecosystem_id
      hash[ecosystem_id] ||= []
      hash[ecosystem_id] << role
    end

    page_models = Content::Models::Page
      .joins(:book)
      .where(book: { uuid: params[:cnx_book_id],
                     content_ecosystem_id: ecosystem_id_role_map.keys },
             uuid: params[:cnx_page_id])

    # If page_models.size > 1, the user is in 2 courses with the same CC book (not allowed)
    page_model = page_models.order(:created_at).last

    if page_model.blank?
      valid_books = Content::Models::Book.where(content_ecosystem_id: ecosystem_id_role_map.keys)
                                         .to_a
      valid_book_with_cnx_book_id = valid_books.select{ |book| book.uuid == params[:cnx_book_id] }
                                               .first

      if !valid_book_with_cnx_book_id.nil?
        # Book is valid for the user, but page is invalid
        code = :invalid_page
        valid_books = [valid_book_with_cnx_book_id]
      elsif !valid_books.empty?
        # Book is invalid for the user, but there are other valid books
        code = :invalid_book
      else
        # Not a CC student
        code = :not_a_cc_student
      end
      
      json_hash = { errors: [{code: code}], valid_books: valid_books.map(&:url) }
      return render(json: json_hash, status: :unprocessable_entity)
    end

    ecosystem_id = page_model.book.content_ecosystem_id
    roles = ecosystem_id_role_map[ecosystem_id]
    # If roles.size > 1, the user is in 2 courses with the same CC book (not allowed)
    # We are guaranteed to have at least one role here, since we already filtered the page above
    role = roles.first

    page = Content::Page.new(strategy: page_model.wrap)

    task = GetConceptCoach[role: role, page: page].task

    respond_with task, represent_with: Api::V1::TaskRepresenter
  end

end
