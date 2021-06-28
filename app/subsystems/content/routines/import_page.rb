class Content::Routines::ImportPage
  lev_routine express_output: :page

  uses_routine Content::Routines::TagResource, as: :tag
  uses_routine Content::Routines::ImportExercises, as: :import_exercises

  protected

  # Imports and saves a Cnx::Page as a Content::Models::Page into the given book's tree
  # Returns the Content::Models::Page object
  def exec(ox_page:, book:, book_indices:, parent_book_part_uuid:, save: true, all_tags: nil)
    ecosystem = book.ecosystem

    ox_page.convert_content!

    outputs.page = Content::Models::Page.new(
      url: ox_page.url,
      title: ox_page.title,
      content: ox_page.content,
      book: book,
      book_indices: book_indices,
      book_location: ox_page.book_location || [],
      uuid: ox_page.uuid,
      short_id: ox_page.short_id,
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
      tags: ox_page.tags,
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
