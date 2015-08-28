class ImportEcosystemManifest

  lev_routine express_output: :ecosystem

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :fetch_and_import,
                                                     translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Content::Manifest as a new Content::Ecosystem
  # Returns the new Content::Ecosystem
  def exec(manifest:)
    # Handle only 1 book per ecosystem for now
    raise IllegalState if manifest.book_cnx_ids.size != 1
    book_cnx_ids = manifest.book_cnx_ids.first
    run(:fetch_and_import, id: book_cnx_ids,
                           ecosystem_title: manifest.ecosystem_title,
                           exercise_uids: manifest.exercise_uids)
  end

end
