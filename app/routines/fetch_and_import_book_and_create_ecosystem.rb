class FetchAndImportBookAndCreateEcosystem

  lev_routine express_output: :ecosystem

  uses_routine Content::ImportBook, as: :import_book,
               translations: { outputs: { type: :verbatim } }

  protected

  # Returns a Content::Ecosystem containing a book obtained from the given CNX id
  def exec(book_cnx_id:, ecosystem_title: nil, exercise_uids: nil, concept_coach_tag: nil)
    cnx_book = OpenStax::Cnx::V1.book(id: book_cnx_id)
    eco_title ||= "#{cnx_book.title} (#{cnx_book.uuid}@#{cnx_book.version}) - #{Time.now.utc}"
    outputs[:ecosystem] = Content::Ecosystem.create!(title: eco_title)
    run(:import_book, cnx_book: cnx_book,
                      ecosystem: outputs[:ecosystem],
                      exercise_uids: exercise_uids,
                      concept_coach_tag: concept_coach_tag)
  end

end
