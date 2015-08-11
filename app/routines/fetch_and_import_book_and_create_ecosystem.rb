class FetchAndImportBookAndCreateEcosystem

  lev_routine express_output: :ecosystem

  uses_routine Content::ImportBook, as: :import_book,
               translations: { outputs: { type: :verbatim } }

  protected

  # Returns an Ecosystem::Ecosystem containing a book obtained from the given CNX id
  def exec(id:)
    cnx_book = OpenStax::Cnx::V1.book(id: id)
    outputs[:ecosystem] = Ecosystem::Ecosystem.create!(title: cnx_book.title)
    run(:import_book, cnx_book: cnx_book, ecosystem: outputs[:ecosystem])
  end

end
