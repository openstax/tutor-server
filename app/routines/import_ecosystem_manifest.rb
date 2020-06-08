class ImportEcosystemManifest
  lev_routine express_output: :ecosystem,
              active_job_enqueue_options: { queue: :maintenance },
              use_jobba: true

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :fetch_and_import,
                                                     translations: { outputs: { type: :verbatim } }

  class << self
    # Since we can't write the Content::Manifest directly to the database, we serialize it as YAML
    def perform_later(manifest:, comments: nil)
      manifest = manifest.to_yaml unless manifest.is_a?(String)

      super(manifest: manifest, comments: comments)
    end
  end

  protected

  # Imports and saves a Content::Manifest as a new Content::Models::Ecosystem
  # Returns the new Content::Models::Ecosystem
  def exec(manifest:, comments: nil)
    manifest = Content::Manifest.from_yaml(manifest) if manifest.is_a?(String)

    fatal_error(code: :invalid_manifest) unless manifest.valid?
    fatal_error(code: :multiple_books) if manifest.books.size > 1

    book = manifest.books.first

    run(:fetch_and_import,
        archive_url: book.archive_url,
        book_cnx_id: book.cnx_id,
        reading_processing_instructions: book.reading_processing_instructions,
        exercise_uids: book.exercise_ids,
        comments: comments)
  end
end
