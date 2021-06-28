class FetchAndImportBookAndCreateEcosystem
  lev_routine express_output: :ecosystem

  uses_routine Content::ImportBook, as: :import_book, translations: { outputs: { type: :verbatim } }

  protected

  # Returns a Content::Models::Ecosystem containing a book obtained from the given uuid and version
  def exec(
    archive_version:,
    book_uuid:,
    book_version:,
    reading_processing_instructions:,
    exercise_uids: nil,
    comments: nil
  )
    openstax_book = OpenStax::Content::Book.new(
      archive_version: archive_version, uuid: book_uuid, version: book_version
    )

    outputs.ecosystem = Content::Models::Ecosystem.create! comments: comments

    run(
      :import_book,
      openstax_book: openstax_book,
      ecosystem: outputs.ecosystem,
      reading_processing_instructions: reading_processing_instructions,
      exercise_uids: exercise_uids
    )

    outputs.ecosystem.update_attribute :title, outputs.ecosystem.set_title

    return if outputs.ecosystem.books.empty?

    Content::UploadEcosystemManifestToValidator.perform_later outputs.ecosystem.manifest.to_yaml
  end
end
