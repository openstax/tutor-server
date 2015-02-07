class ImportBook

  lev_routine

  uses_routine ImportPage, as: :import

  protected

  # Recursively imports items in a CNX collection into the given book
  def import_collection(book, collection, options = {})
    # Flatten out the tree
    chapter = Chapter.new(book: book, title: collection['title'])

    collection['contents'].each do |item|
      if item['id'] == 'subcol'
        # Don't save chapters that only contain subchapters
        import_collection(book, item, options)
      else
        # Only save collections 1 level above leaves of the book tree
        chapter.save unless chapter.persisted?

        run(:import,
            item['id'],
            options.merge(chapter: chapter, title: item['title']))
      end
    end
  end

  # Imports and saves a CNX book as a Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(id, options = {})
    out = run(:import, id, options).outputs
    outputs[:resource] = out[:resource]
    outputs[:hash] = out[:hash]

    outputs[:book] = Book.new(resource: outputs[:resource])

    import_collection(outputs[:book], outputs[:hash]['tree'])

    outputs[:book].save
    transfer_errors_from outputs[:book], type: :verbatim
  end

end
