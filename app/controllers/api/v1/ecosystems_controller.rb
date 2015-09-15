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

  api :GET, '/ecosystems/:ecosystem_id/exercises(/:pool_types)',
            "Returns exercises for a given ecosystem, filtered by the page_ids param and optionally an array of pool_types"
  description <<-EOS
    Returns a list of assignable exercises associated with the pages with the given ID's.
    If no page_ids are specified, returns an empty array.

    #{json_schema(Api::V1::ExerciseSearchRepresenter, include: :readable)}
  EOS
  def exercises
    ecosystem = ::Content::Ecosystem.find(params[:id])

    respond_with_ecosystem_exercises(ecosystem, params[:pool_types])
  end

  protected

  def respond_with_ecosystem_readings(ecosystem)
    OSU::AccessPolicy.require_action_allowed!(:readings, current_api_user, ecosystem)

    # For the moment, we're assuming just one book per ecosystem
    books = ecosystem.books
    raise NotYetImplemented if books.count > 1

    respond_with books, represent_with: Api::V1::BookTocsRepresenter
  end

  def respond_with_ecosystem_exercises(ecosystem, pool_types = nil)
    OSU::AccessPolicy.require_action_allowed!(:exercises, current_api_user, ecosystem)

    pages = ecosystem.pages_by_ids(params[:page_ids])

    pool_types = [pool_types].flatten.compact

    # Default types
    pool_types = ['reading_dynamic', 'reading_try_another', 'homework_core',
                  'homework_dynamic', 'practice_widget', 'all_exercises'] if pool_types.empty?

    # Convert to set
    pool_types = Set.new pool_types

    # Build map of pool types to exercises
    pools = {}
    pools['reading_dynamic'] = ecosystem.reading_dynamic_pools(pages: pages) \
      if pool_types.include?('reading_dynamic')
    pools['reading_try_another'] = ecosystem.reading_try_another_pools(pages: pages) \
      if pool_types.include?('reading_try_another')
    pools['homework_core'] = ecosystem.homework_core_pools(pages: pages) \
      if pool_types.include?('homework_core')
    pools['homework_dynamic'] = ecosystem.homework_dynamic_pools(pages: pages) \
      if pool_types.include?('homework_dynamic')
    pools['practice_widget'] = ecosystem.practice_widget_pools(pages: pages) \
      if pool_types.include?('practice_widget')
    pools['all_exercises'] = ecosystem.all_exercises_pools(pages: pages) \
      if pool_types.include?('all_exercises')

    # Build map of exercise uids to representations, with pool type
    exercise_representations = pools.each_with_object({}) do |(pool_type, pools), hash|
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
