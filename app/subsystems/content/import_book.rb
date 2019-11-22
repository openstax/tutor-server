class Content::ImportBook

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part,
                                                  translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::ImportExercises, as: :import_exercises
  uses_routine Content::Routines::TransformAndCachePageContent, as: :transform_and_cache_content
  uses_routine Content::Routines::PopulateExercisePools, as: :populate_exercise_pools

  protected

  # Imports and saves a Cnx::Book as a Content::Models::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:, ecosystem:, reading_processing_instructions: nil, exercise_uids: nil)
    reading_processing_instructions = reading_processing_instructions.to_a
    book = Content::Models::Book.new(
        url: cnx_book.canonical_url,
        uuid: cnx_book.uuid,
        short_id: cnx_book.short_id,
        version: cnx_book.version,
        title: cnx_book.title,
        baked_at: cnx_book.baked,
        is_collated: cnx_book.collated,
        content: cnx_book.root_book_part.contents,
        content_ecosystem_id: ecosystem.id,
        reading_processing_instructions: reading_processing_instructions.map(&:to_h)
    )

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part, book: book, save: false)

    Content::Models::Book.import [book], recursive: true, validate: false

    run(:transform_and_cache_content, book: book, pages: book.chapters.reload.flat_map(&:pages))

    import_page_map = {}
    import_page_tags = outputs.page_taggings.filter { |pt| pt.tag.import? }.map(&:reload)
    import_page_tags.each { |page_tag| import_page_map[page_tag.tag.value] = page_tag.page }

    outputs.exercises = []
    imported_exercise_numbers = Set.new

    # If an exercise could go into multiple pages,
    # we always break ties by putting it in the page that appears last in the book
    page_block = ->(exercise_wrapper) do
      tags = exercise_wrapper.import_tags
      pages = tags.map { |tag| import_page_map[tag] }.compact.uniq
      pages.max_by(&:book_location)
    end

    query_hash = if exercise_uids.nil?
      # Exercises not in manifest
      { tag: import_page_tags.map { |pt| pt.tag.value } }
    else
      # Exercises in manifest
      { uid: exercise_uids }
    end

    run(:import_exercises, ecosystem: ecosystem, page: page_block, query_hash: query_hash)

    outs = run(:populate_exercise_pools, book: book).outputs

    outputs.book = book
    outputs.chapters = outs.chapters
    outputs.pages = outs.pages

    # Send ecosystem information to Biglearn
    OpenStax::Biglearn::Api.create_ecosystem(ecosystem: ecosystem)
  end

end
