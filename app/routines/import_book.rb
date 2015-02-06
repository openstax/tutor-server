class ImportBook

  lev_routine

  uses_routine ImportPage, as: :import

  protected

  # Recursively imports items in a CNX collection
  def import_collection(book, collection, options = {})
    collection['contents'].each do |item|
      if item['id'] == 'subcol'
        import_collection(book, item, options)
      else
        reading = run(:import,
                      item['id'],
                      options.merge(chapter: nil,
                                    title: item['title'])).outputs[:reading]
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
