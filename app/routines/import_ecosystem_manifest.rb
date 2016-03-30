class ImportEcosystemManifest

  lev_routine express_output: :ecosystem

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :fetch_and_import,
                                                     translations: { outputs: { type: :verbatim } }

  # Since we can't write the Content::Manifest to the database, we process it before queuing the job
  def self.perform_later(manifest:, comments: nil)
    FetchAndImportBookAndCreateEcosystem.perform_later(
      fetch_and_import_routine_args(manifest: manifest, comments: comments)
    )
  end

  protected

  def self.fetch_and_import_routine_args(manifest:, comments:)
    # Handle only 1 book per ecosystem for now
    raise IllegalState if manifest.book_ids.size != 1

    {
      archive_url: manifest.archive_url,
      book_cnx_id: manifest.book_ids.first,
      ecosystem_title: manifest.ecosystem_title,
      exercise_uids: manifest.exercise_ids,
      comments: comments
    }
  end

  # Imports and saves a Content::Manifest as a new Content::Ecosystem
  # Returns the new Content::Ecosystem
  def exec(manifest:, comments: nil)
    run(:fetch_and_import,
        self.class.fetch_and_import_routine_args(manifest: manifest, comments: comments))
  end

end
