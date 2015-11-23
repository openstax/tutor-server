class Content::ImportBook
  MAX_URL_LENGTH = 2020

  lev_routine outputs: {
                _verbatim: { name: Content::Routines::ImportBookPart,
                             as: :import_book_part },
                exercises: { name: Content::Routines::ImportExercises,
                             as: :import_exercises }
              },
              uses: [{ name: Content::Routines::UpdatePageContent,
                       as: :update_page_content },
                     { name: Content::Routines::PopulateExercisePools,
                       as: :populate_exercise_pools }]


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

    Content::Models::Book.import!([book], recursive: true)

    # Reload book and reset associations so they get reloaded the next time they are used
    book.reload.clear_association_cache

    import_page_tags = result.page_taggings.select { |pt| pt.tag.import? }
    import_page_tags.each(&:reload)

    page_block = ->(exercise_wrapper) {
      tags = Set.new(exercise_wrapper.los + exercise_wrapper.aplos + exercise_wrapper.cnxmods)
      pages = import_page_tags.select { |pt| tags.include?(pt.tag.value) }.collect(&:page).uniq

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
        run(:import_exercises, ecosystem: ecosystem, page: page_block, query_hash: query_hash)
      end
    else
      # Split the uid queries to avoid exceeding the URL limit
      max_uid_length = exercise_uids.map(&:size).max
      uids_per_query = MAX_URL_LENGTH/max_uid_length

      exercise_uids.each_slice(uids_per_query) do |uids|
        query_hash = { id: uids }
        run(:import_exercises, ecosystem: ecosystem, page: page_block, query_hash: query_hash)
      end
    end

    populate_pools = run(:populate_exercise_pools, book: book, save: false)
    page_content = run(:update_page_content, pages: populate_pools.pages, save: false)

    set(book: book, chapters: populate_pools.chapters, pages: page_content.pages)

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

    biglearn_pools = populate_pools.pools.collect do |pool|
      exercise_ids = pool.content_exercise_ids
      exercises = exercise_ids.collect{ |id| biglearn_exercises_by_ids[id] }
      OpenStax::Biglearn::V1::Pool.new(exercises: exercises)
    end

    biglearn_pools_with_uuids = OpenStax::Biglearn::V1.add_pools(biglearn_pools)

    populate_pools.pools.each_with_index do |pool, ii|
      pool.uuid = biglearn_pools_with_uuids[ii].uuid
    end

    Content::Models::Pool.import!(populate_pools.pools)

    # Save ids in page/chapter tables and clear associations so pools get reloaded next time
    pages.each do |page|
      page.save!
      page.clear_association_cache
    end

    chapters.each do |chapter|
      chapter.save!
      chapter.clear_association_cache
    end
  end
end
