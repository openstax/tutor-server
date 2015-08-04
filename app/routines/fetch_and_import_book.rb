class FetchAndImportBook

  lev_routine express_output: :book

  uses_routine Content::ImportBook, as: :import_book,
               translations: { outputs: { type: :verbatim } }

  protected

  # Returns a Cnx::Book based on a CNX ID
  def exec(id:)
    outputs[:cnx_book] = OpenStax::Cnx::V1.book(id: id)
    outputs[:ecosystem] = Ecosystem::Ecosystem.create!
    run(:import_book, cnx_book: outputs[:cnx_book], ecosystem: outputs[:ecosystem])
  end

end
