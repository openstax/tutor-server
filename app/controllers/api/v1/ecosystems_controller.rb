class Api::V1::EcosystemsController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Provides ways to retrieve content such as books and exercises'
    description <<-EOS
      Provides ways to retrieve content such as books and exercises
      Content can be retrieved either by course id or by ecosystem id
    EOS
  end

  api :GET, '/ecosystems/:ecosystem_id/readings', 'Returns readings for a given ecosystem'
  description <<-EOS
    Returns a hierarchical listing of an ecosystem's readings.
    An ecosystem is currently limited to only one book.
    Inside each book there can be chapters and pages.

    #{json_schema(Api::V1::BookTocsRepresenter, include: :readable)}
  EOS
  def readings
    ecosystem = ::Content::Ecosystem.find(params[:id])

    respond_with_ecosystem_readings(ecosystem)
  end

  api :GET, '/ecosystems/:ecosystem_id/exercises',
            "Returns exercises for a given ecosystem, filtered by the page_ids param"
  description <<-EOS
    Returns a list of assignable exercises associated with the pages with the given ID's.
    If no page_ids are specified, returns an empty array.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def exercises
    ecosystem = ::Content::Ecosystem.find(params[:id])

    respond_with_ecosystem_exercises(ecosystem)
  end

  protected

  def respond_with_ecosystem_readings(ecosystem)
    OSU::AccessPolicy.require_action_allowed!(:readings, current_api_user, ecosystem)

    # For the moment, we're assuming just one book per ecosystem
    books = ecosystem.books
    raise NotYetImplemented if books.count > 1

    respond_with books, represent_with: Api::V1::BookTocsRepresenter
  end

  def respond_with_ecosystem_exercises(ecosystem)
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, ecosystem)

    pages = ecosystem.pages_by_ids(params[:page_ids])
    exercises = ecosystem.homework_core_pools(pages: pages).flat_map(&:exercises)

    respond_with exercises, represent_with: Api::V1::ExerciseSearchRepresenter
  end

end
