class Content::Routines::ImportPage
  lev_routine express_output: :page

  uses_routine Content::Routines::TagResource, as: :tag
  uses_routine Content::Routines::ImportExercises, as: :import_exercises

  protected

  # Imports and saves a Cnx::Page as a Content::Models::Page into the given book's tree
  # Returns the Content::Models::Page object
  def exec(cnx_page:, book:, book_indices:, parent_book_part_uuid:, save: true, all_tags: nil)
    ecosystem = book.ecosystem

    cnx_page.convert_content!

    outputs.page = Content::Models::Page.new(
      url: cnx_page.canonical_url,
      title: cnx_page.title,
      content: cnx_page.content,
      book: book,
      book_indices: book_indices,
      book_location: cnx_page.book_location || [],
      uuid: cnx_page.uuid,
      version: cnx_page.version,
      short_id: cnx_page.short_id,
      parent_book_part_uuid: parent_book_part_uuid
    )
    book.pages << outputs.page
    outputs.page.save if save
    transfer_errors_from(outputs.page, { type: :verbatim }, true)

    # Tag the Page
    outs = run(
      :tag,
      ecosystem: ecosystem,
      resource: outputs.page,
      tags: cnx_page.tags,
      tagging_class: Content::Models::PageTag,
      save_tags: save,
      all_tags: all_tags
    ).outputs
    outputs.all_tags = outs.all_tags

    return unless save

    # Get Exercises from OpenStax Exercises that match the LO, AP LO or UUID tags
    import_tags = outs.tags.select(&:import?).map(&:value)

    return if import_tags.empty?

    run(
      :import_exercises, ecosystem: ecosystem, page: outputs.page, query_hash: { tag: import_tags }
    )
  end
end
