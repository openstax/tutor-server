class Content::Api::ImportBook

  lev_routine

  uses_routine Content::ImportCnxResource,
               as: :cnx_import,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::ImportPage, as: :page_import

  protected

  # Recursively imports items in a CNX collection into the given book
  def import_collection(parent_book, hash, options = {})
    book = Content::Book.create(parent_book: parent_book,
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

    content_book = import_collection(nil, outputs[:hash]['tree'], options)
    content_book.url = outputs[:url]
    content_book.content = outputs[:content]

    entity_book = Entity::CreateBook.call.outputs.book
    content_book.entity_book = entity_book

    content_book.save

    transfer_errors_from(content_book, {type: :verbatim}, true)

    outputs[:book] = entity_book
    outputs[:content_book] = content_book if Rails.env.test?
  end

end

