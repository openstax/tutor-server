class Content::ImportBook

  # Kind of a hack to limit how many exercises we request at a time and avoid timeouts
  # It is set to 2020 in the test environment so as to not break basically all the cassettes
  MAX_EXERCISES_REQUEST_LENGTH = Rails.env.test? ? 2020 : 1000

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part,
                                                  translations: { outputs: { type: :verbatim } }
  uses_routine Content::Routines::ImportExercises, as: :import_exercises
  uses_routine Content::Routines::UpdatePageContent, as: :update_page_content
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
        content: cnx_book.root_book_part.contents,
        content_ecosystem_id: ecosystem.id,
        reading_processing_instructions: reading_processing_instructions.map(&:to_h)
    )

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part, book: book, save: false)

    Content::Models::Book.import [book], recursive: true, validate: false

    # Reset chapters association so it gets reloaded the next time it is used
    book.chapters.reset

    import_page_tags = outputs[:page_taggings].select{ |pt| pt.tag.import? }
    import_page_tags.each(&:reload)

    import_page_map = {}
    import_page_tags.each{ |page_tag| import_page_map[page_tag.tag.value] = page_tag.page }

    outputs[:exercises] = []
    imported_exercise_numbers = Set.new

    page_block = ->(exercise_wrapper) do
      tags = exercise_wrapper.import_tags
      pages = tags.map{ |tag| import_page_map[tag] }.compact.uniq
      pages.max_by(&:book_location)
    end

    if exercise_uids.nil?
      # Split the tag queries to avoid exceeding the URL limit
      max_tag_length = import_page_tags.map{ |pt| pt.tag.value.size }.max || 1
      tags_per_query = MAX_EXERCISES_REQUEST_LENGTH/max_tag_length
      import_page_tags.each_slice(tags_per_query) do |page_tags|
        query_hash = { tag: page_tags.map{ |pt| pt.tag.value } }

        new_exercises = run(
          :import_exercises, ecosystem: ecosystem, page: page_block,
          query_hash: query_hash, excluded_exercise_numbers: imported_exercise_numbers
        ).outputs.exercises
        outputs[:exercises] += new_exercises
        imported_exercise_numbers += new_exercises.map(&:number)
      end
    else
      # Split the uid queries to avoid exceeding the URL limit
      max_uid_length = exercise_uids.map(&:size).max || 1
      uids_per_query = MAX_EXERCISES_REQUEST_LENGTH/max_uid_length
      exercise_uids.each_slice(uids_per_query) do |uids|
        query_hash = { id: uids }

        new_exercises = run(
          :import_exercises, ecosystem: ecosystem, page: page_block,
          query_hash: query_hash, excluded_exercise_numbers: imported_exercise_numbers
        ).outputs.exercises
        outputs[:exercises] += new_exercises
        imported_exercise_numbers += new_exercises.map(&:number)
      end
    end

    outs = run(:populate_exercise_pools, book: book).outputs
    pools = outs.pools
    chapters = outs.chapters
    pages = outs.pages
    pages = run(:update_page_content, pages: pages, save: false).outputs.pages

    outputs[:book] = book
    outputs[:chapters] = chapters
    outputs[:pages] = pages

    # Send ecosystem information to Biglearn
    OpenStax::Biglearn::Api.create_ecosystems(ecosystem: ecosystem)
  end

end
