class Content::Routines::ImportPage

  lev_routine express_output: :page

  uses_routine Content::Routines::FindOrCreateTags,
               as: :find_or_create_tags,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::TagResource,
               as: :tag,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::Routines::ImportExercises,
               as: :import_exercises,
               translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Cnx::Page as a Content::Models::Page
  # into the given Content::Models::Chapter
  # Returns the Content::Models::Page object
  def exec(cnx_page:, chapter:, number: nil, book_location: nil, save: true)
    ecosystem = chapter.book.ecosystem

    outputs.page = Content::Models::Page.new(url: cnx_page.canonical_url,
                                             title: cnx_page.title,
                                             content: cnx_page.converted_content,
                                             chapter: chapter,
                                             number: number,
                                             book_location: book_location,
                                             baked_book_location: cnx_page.baked_book_location,
                                             uuid: cnx_page.uuid,
                                             version: cnx_page.version,
                                             short_id: cnx_page.short_id)
    chapter.pages << outputs.page unless chapter.nil?
    outputs.page.save if save
    transfer_errors_from(outputs.page, {type: :verbatim}, true)

    tags = cnx_page.tags

    # Tag the Page
    run(:find_or_create_tags, ecosystem: ecosystem, input: tags)
    run(:tag, outputs.page, outputs.tags, tagging_class: Content::Models::PageTag, save: save)

    outputs.exercises = []

    return unless save

    # Get Exercises from OpenStax Exercises that match the LO, AP LO or UUID tags
    import_tags = outputs.tags.select(&:import?).map(&:value)

    return if import_tags.empty?

    run(:import_exercises, ecosystem: ecosystem,
                           page: outputs.page,
                           query_hash: {tag: import_tags})
  end

end
