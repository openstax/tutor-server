class Content::Routines::ImportPage
  lev_routine outputs: {
                page: :_self,
                exercises: :_self,
                _verbatim: [{ name: Content::Routines::FindOrCreateTags,
                              as: :find_or_create_tags },
                            { name: Content::Routines::TagResource, as: :tag },
                            { name: Content::Routines::ImportExercises,
                              as: :import_exercises }]
              }

  protected
  # Imports and saves a Cnx::Page as a Content::Models::Page
  # into the given Content::Models::Chapter
  # Returns the Content::Models::Page object
  def exec(cnx_page:, chapter:, number: nil, book_location: nil, save: true)
    ecosystem = chapter.book.ecosystem

    set(page: Content::Models::Page.new(url: cnx_page.canonical_url,
                                        title: cnx_page.title,
                                        content: cnx_page.converted_content,
                                        chapter: chapter,
                                        number: number,
                                        book_location: book_location,
                                        uuid: cnx_page.uuid,
                                        version: cnx_page.version))
    result.page.save if save

    transfer_errors_from(result.page)

    chapter.pages << result.page unless chapter.nil?

    tags = cnx_page.tags

    # Tag the Page
    run(:find_or_create_tags, ecosystem: ecosystem, input: tags)
    run(:tag, result.page,
              result.tags,
              tagging_class: Content::Models::PageTag,
              save: save)

    result.page.page_tags = result.taggings

    set(exercises: [])

    return unless save

    # Get Exercises from OpenStax Exercises that match the LO, AP LO or UUID tags
    import_tags = result.tags.select(&:import?).collect(&:value)

    return if import_tags.empty?

    run(:import_exercises, ecosystem: ecosystem,
                           page: result.page,
                           query_hash: { tag: import_tags })
  end
end
