class Content::Api::ImportBook

  lev_routine

  uses_routine Content::ImportCnxResource,
               as: :cnx_import,
               translations: { outputs: { type: :verbatim } }

  uses_routine Content::ImportPage, as: :page_import

  protected
  # Imports and saves a CNX book as a Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(id, options = {})
    @options = options
    run(:cnx_import, id, @options.merge(book: true))

    outputs[:book] = import_book_tree(outputs[:hash]['tree'])
    outputs[:book].url = outputs[:url]
    outputs[:book].content = outputs[:content]
    outputs[:book].save

    transfer_errors_from(outputs[:book], type: :verbatim)
  end

  private
  def import_book_tree(book_tree, parent = nil)
    collection = store_collection(book_tree['title'] || '', parent)
    import_children(collection, book_tree['contents'])
    collection
  end

  def store_collection(title, parent)
    if parent.present?
      parent.child_books.create(title: title, path: @options[:collection_path])
    else
      Content::Book.create(title: title)
    end
  end

  def import_children(parent, children)
    collection_index, page_index = 0, 0

    children.each do |child|
      if child['id'] == 'subcol' # sub-collection
        import_sub_collection(parent, child, collection_index += 1)
      else
        import_page(parent, child, page_index += 1)
      end
    end
  end

  def import_sub_collection(parent, sub_collection, index)
    @options[:collection_path] = construct_path(parent, index)
    import_book_tree(sub_collection, parent)
  end

  def import_page(parent, page, index)
    @options[:page_path] = construct_path(parent, index)
    @options[:title] = page['title']
    run(:page_import, page['id'], parent, @options)
  end

  def construct_path(parent, index)
    return index if parent.nil?
    [parent.path, index].reject(&:blank?).join('.')
  end

end
