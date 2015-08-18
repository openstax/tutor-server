class Content::ImportBook

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part,
                                                  translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::ImportExercises, as: :import_exercises,
                                                  translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::UpdatePageContent, as: :update_page_content
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  protected

  # Imports and saves a Cnx::Book as an Content::Models::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:, ecosystem:)
    book = Content::Models::Book.new(url: cnx_book.canonical_url,
                                     uuid: cnx_book.uuid,
                                     version: cnx_book.version,
                                     title: cnx_book.title,
                                     content: cnx_book.root_book_part.contents,
                                     content_ecosystem_id: ecosystem.id)

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part, book: book, save: false)

    Content::Models::Book.import! [book], recursive: true

    objective_page_tags = outputs[:page_taggings].select{ |pt| pt.tag.lo? || pt.tag.aplo? }
    query_hash = { tag: objective_page_tags.collect{ |pt| pt.tag.value } }
    page_block = ->(exercise_wrapper) {
      tags = Set.new(exercise_wrapper.los + exercise_wrapper.aplos)
      pages = objective_page_tags.select{ |opt| tags.include?(opt.tag.value) }
                                 .collect{ |opt| opt.page }

      # Blow up if there is more than one page for an exercise
      fatal_error(code: :multiple_pages_for_one_exercise,
                  message: "Multiple pages were found for an exercise.\nExercise: #{
                    exercise_wrapper.uid}\nPages:\n#{pages.collect{ |pg| pg.url }.join("\n")}") \
        if pages.size != 1
      pages.first
    }

    if objective_page_tags.empty?
      outputs[:exercises] = []
    else
      outputs[:exercises] = nil
      run(:import_exercises, ecosystem: ecosystem, page: page_block, query_hash: query_hash)
    end

    # Need a double reload here for it to work for some reason
    # Use preload instead of eager_load here to avoid a memory usage spike
    pages = book.reload.pages(true).preload(exercises: {exercise_tags: :tag})
    pages = run(:update_page_content, pages: pages, save: false).outputs.pages
    outs = run(:populate_exercise_pools, pages: pages, save: false).outputs
    pages = outs.pages
    pools = outs.pools.flatten

    outputs[:pages] = pages

    #
    # Send exercise and pool info to Biglearn and get back the pool UUID's
    #
    # First, build up local lists of the exercises and tags, then
    # send those lists all at once to one call each in the BL API.
    #

    biglearn_exercises_by_ids = outputs[:exercises].each_with_object({}) do |ex, hash|
      exercise_url = Addressable::URI.parse(ex.url)
      exercise_url.scheme = nil
      exercise_url.path = exercise_url.path.split('@').first
      hash[ex.id] = OpenStax::Biglearn::V1::Exercise.new(
        question_id: exercise_url.to_s,
        version: ex.version,
        tags: ex.exercise_tags.collect{ |ex| ex.tag.value }
      )
    end
    biglearn_exercises = biglearn_exercises_by_ids.values

    OpenStax::Biglearn::V1.add_exercises(biglearn_exercises)

    biglearn_pools = pools.collect do |pool|
      exercise_ids = pool.content_exercise_ids
      exercises = exercise_ids.collect{ |id| biglearn_exercises_by_ids[id] }
      OpenStax::Biglearn::V1::Pool.new(exercises: exercises)
    end
    biglearn_pools_with_uuids = OpenStax::Biglearn::V1.add_pools(biglearn_pools)
    pools.each_with_index do |pool, ii|
      pool.uuid = biglearn_pools_with_uuids[ii].uuid
    end

    Content::Models::Pool.import! pools
    # Replace with UPSERT once we support it
    pages.each{ |page| page.save! }
  end

end
