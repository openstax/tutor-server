module Import
  class Book

    lev_routine

    uses_routine Import::CnxResource,
                 as: :cnx_import,
                 translations: { outputs: { type: :verbatim } }

    uses_routine Import::Page, as: :page_import

    protected

    # Recursively imports items in a CNX collection into the given book
    def import_collection(parent_book, hash, options = {})
      book = ::Book.create(parent_book: parent_book,
                           title: hash['title'] || '')

      parent_book.child_books << book unless parent_book.nil?

      hash['contents'].each do |item|
        if item['id'] == 'subcol'
          import_collection(book, item, options)
        else
          run(:page_import, item['id'], book, 
                            options.merge(title: item['title']))
        end
      end

      book
    end

    # Imports and saves a CNX book as a Book
    # Returns the Book object, Resource object and collection JSON as a hash
    def exec(id, options = {})
      run(:cnx_import, id, options.merge(book: true))

      outputs[:book] = import_collection(nil, outputs[:hash]['tree'], options)
      outputs[:book].resource = outputs[:resource]
      outputs[:book].save

      transfer_errors_from outputs[:book], type: :verbatim
    end

  end
end
