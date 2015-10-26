class Content::ImportBook

  MAX_URL_LENGTH = 2020

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part,
                                                  translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::ImportExercises, as: :import_exercises
  uses_routine Content::Routines::UpdatePageContent, as: :update_page_content
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  protected

  # Imports and saves a Cnx::Book as a Content::Models::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:, ecosystem:, exercise_uids: nil)
    book = Content::Models::Book.new(url: cnx_book.canonical_url,
                                     uuid: cnx_book.uuid,
                                     version: cnx_book.version,
                                     title: cnx_book.title,
                                     content: cnx_book.root_book_part.contents,
                                     content_ecosystem_id: ecosystem.id)

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part, book: book, save: false)

    Content::Models::Book.import! [book], recursive: true

    import_page_tags = outputs[:page_taggings].select{ |pt| pt.tag.import? }

    outputs[:exercises] = []
    page_block = ->(exercise_wrapper) {
      tags = Set.new(exercise_wrapper.los + exercise_wrapper.aplos + exercise_wrapper.uuids)
      pages = import_page_tags.select{ |pt| tags.include?(pt.tag.value) }
                              .collect{ |pt| pt.page }.uniq

      # Blow up if there is more than one page for an exercise
      fatal_error(code: :multiple_pages_for_one_exercise,
                  message: "Multiple pages were found for an exercise.\nExercise: #{
                    exercise_wrapper.uid}\nPages:\n#{pages.collect{ |pg| pg.url }.join("\n")}") \
        if pages.size != 1
      pages.first
    }

    if exercise_uids.nil?
      # Split the tag queries to avoid exceeding the URL limit
      max_tag_length = import_page_tags.map{ |pt| pt.tag.value.size }.max
      tags_per_query = MAX_URL_LENGTH/max_tag_length
      import_page_tags.each_slice(tags_per_query) do |page_tags|
        query_hash = { tag: page_tags.collect{ |pt| pt.tag.value } }
        outputs[:exercises] += run(:import_exercises, ecosystem: ecosystem,
                                                      page: page_block,
                                                      query_hash: query_hash).outputs.exercises
      end
    else
      # Split the uid queries to avoid exceeding the URL limit
      max_uid_length = exercise_uids.map(&:size).max
      uids_per_query = MAX_URL_LENGTH/max_uid_length
      exercise_uids.each_slice(uids_per_query) do |uids|
        query_hash = { id: uids }
        outputs[:exercises] += run(:import_exercises, ecosystem: ecosystem,
                                                      page: page_block,
                                                      query_hash: query_hash).outputs.exercises
      end
    end

    # Need a double reload here to fully load the newly imported book
    outs = run(:populate_exercise_pools, book: book.reload.reload, save: false).outputs
    pools = outs.pools
    chapters = outs.chapters
    pages = outs.pages
    pages = run(:update_page_content, pages: pages, save: false).outputs.pages

    outputs[:book] = book
    outputs[:chapters] = chapters
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
    chapters.each{ |chapter| chapter.save! }
  end

end
