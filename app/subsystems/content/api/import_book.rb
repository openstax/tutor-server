class Content::Api::ImportBook

  lev_routine

  uses_routine Entity::CreateBook,
               as: :create_book,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::ImportBookPart,
               as: :import_book_part,
               translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Cnx::Book as an Entity::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:)
    run(:create_book)

    run(:import_book_part, cnx_book_part: cnx_book.root_book_part,
                           book: outputs[:book])
    transfer_errors_from(outputs[:book_part], {type: :verbatim}, true)
  end

end
