class FetchAndImportBookAndCreateEcosystem

  lev_routine express_output: :ecosystem

  uses_routine Content::ImportBook, as: :import_book, translations: { outputs: { type: :verbatim } }

  protected

  # Returns a Content::Ecosystem containing a book obtained from the given CNX id
  def exec(book_cnx_id:, archive_url: nil,
           reading_processing_instructions: nil, exercise_uids: nil, comments: nil)
    archive_url ||= OpenStax::Cnx::V1.archive_url_base
    OpenStax::Cnx::V1.with_archive_url(archive_url) do
      cnx_book = OpenStax::Cnx::V1.book(id: book_cnx_id)

      outputs[:ecosystem] = Content::Ecosystem.create! comments: comments

      run(:import_book, cnx_book: cnx_book,
                        ecosystem: outputs[:ecosystem],
                        reading_processing_instructions: reading_processing_instructions,
                        exercise_uids: exercise_uids)
    end
  end

end
