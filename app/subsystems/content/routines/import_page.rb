class Content::Routines::ImportPage
  lev_routine express_output: :page

  uses_routine Content::Routines::FindOrCreateTags,
               as: :find_or_create_tags, translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::TagResource,
               as: :tag, translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::ImportExercises,
               as: :import_exercises, translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Cnx::Page as a Content::Models::Page into the given book's tree
  # Returns the Content::Models::Page object
  def exec(cnx_page:, book:, book_location: nil, save: true)
    ecosystem = book.ecosystem

    cnx_page.convert_content!

    outputs.page = Content::Models::Page.new(
      url: cnx_page.canonical_url,
      title: cnx_page.title,
      content: cnx_page.content,
      book: book,
      book_location: book_location || cnx_page.book_location || [],
      uuid: cnx_page.uuid,
      version: cnx_page.version,
      short_id: cnx_page.short_id
    )
    book.pages << outputs.page
    outputs.page.save if save
    transfer_errors_from(outputs.page, { type: :verbatim }, true)

    tags = cnx_page.tags

    # Tag the Page
    run(:find_or_create_tags, ecosystem: ecosystem, input: tags)
    run(:tag, outputs.page, outputs.tags, tagging_class: Content::Models::PageTag, save: save)

    outputs.exercises = []

    return unless save

    # Get Exercises from OpenStax Exercises that match the LO, AP LO or UUID tags
    import_tags = outputs.tags.select(&:import?).map(&:value)

    return if import_tags.empty?

    run(
      :import_exercises, ecosystem: ecosystem, page: outputs.page, query_hash: { tag: import_tags }
    )
  end
end
