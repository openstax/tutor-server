class Api::V1::EcosystemsController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Provides ways to retrieve content such as books and exercises'
    description <<-EOS
      Provides ways to retrieve content such as books and exercises
      Content can be retrieved either by course id or by ecosystem id
    EOS
  end

  api :GET, '/ecosystems', 'Returns all available ecosystems'
  description <<-EOS
    Returns a listing of all the ecosytems in that have been created

    #{json_schema(Api::V1::EcosystemsRepresenter, include: :readable)}
  EOS
  def index
    OSU::AccessPolicy.require_action_allowed!(:ecosystems, current_human_user, Content::Ecosystem)
    ecosystems = Content::ListEcosystems[]
    respond_with ecosystems, represent_with: Api::V1::EcosystemsRepresenter
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

    OSU::AccessPolicy.require_action_allowed!(:readings, current_api_user, ecosystem)

    # For the moment, we're assuming just one book per ecosystem
    books = ecosystem.books
    raise NotYetImplemented if books.count > 1

    respond_with books, represent_with: Api::V1::BookTocsRepresenter
  end

  api :GET, '/ecosystems/:ecosystem_id/exercises(/:pool_types)',
            "Returns exercises for a given ecosystem, filtered by the page_ids param and optionally an array of pool_types"
  description <<-EOS
    Returns a list of assignable exercises associated with the pages with the given ID's.
    If no page_ids are specified, returns an empty array.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def exercises
    ecosystem = ::Content::Ecosystem.find(params[:id])

    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, ecosystem)

    pools_map = GetEcosystemPoolsByPageIdsAndPoolTypes[ecosystem: ecosystem,
                                                       page_ids: params[:page_ids],
                                                       pool_types: params[:pool_types]]

    # Build map of exercise uids to representations, with pool type
    exercise_representations = pools_map.each_with_object({}) do |(pool_type, pools), hash|
      pools.flat_map{ |pool| pool.exercises(preload_tags: true) }.each do |exercise|
        hash[exercise.uid] ||= Api::V1::ExerciseRepresenter.new(exercise).to_hash
        hash[exercise.uid]['pool_types'] ||= []
        hash[exercise.uid]['pool_types'] << pool_type
      end
    end

    results = Hashie::Mash.new(items: exercise_representations.values)

    respond_with results, represent_with: Api::V1::ExerciseSearchRepresenter
  end

end
