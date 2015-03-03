class Content::Api::ImportBook

  lev_routine

  uses_routine Content::ImportCnxResource,
               as: :cnx_import,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::ImportPage, as: :page_import

  protected

  # Recursively imports items in a CNX collection into the given book
  def import_collection(parent_book_part:, hash:, path:, options: {})
    book_part = Content::BookPart.create(parent_book_part: parent_book_part,
                                         title: hash['title'] || '',
                                         path: path)

    parent_book_part.child_book_parts << book_part unless parent_book_part.nil?

    hash['contents'].each_with_index do |item, ii|
      item_path = "#{path.nil? ? '' : path + '.'}#{ii+1}"
      if item['id'] == 'subcol'
        import_collection(parent_book_part: book_part, hash: item, path: item_path, options: options)
      else
        run(:page_import, id: item['id'], book_part: book_part, path: item_path,
                          options: options.merge(title: item['title']))
      end
    end

    book_part
  end

  # Imports and saves a CNX book as a Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(id, options = {})
    run(:cnx_import, id, options.merge(book: true))

    content_book_part = import_collection(parent_book_part: nil, 
                                          hash: outputs[:hash]['tree'], 
                                          path: nil,
                                          options: options)
    content_book_part.url = outputs[:url]
    content_book_part.content = outputs[:content]

    book = Entity::CreateBook.call.outputs.book
    content_book_part.book = book

    content_book_part.save

    transfer_errors_from(content_book_part, {type: :verbatim}, true)

    outputs[:book] = book
    outputs[:content_book_part] = content_book_part if Rails.env.test?
  end

end

