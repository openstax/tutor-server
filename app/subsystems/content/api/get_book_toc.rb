class Content::Api::GetBookToc

  lev_routine

  protected

  def exec(entity_book_id:)
    book = Content::Book.find(entity_book_id: entity_book_id)
    # Quick and dirty implementation (cache this stuff later)
    outputs[:toc] = book_toc(book)
  end

  def book_toc(book)
    toc = {}

    toc[:id] = book.id
    toc[:title] = book.title
    toc[:type] = 'part'
    toc[:children] = []

    book.child_books.each do |child_book|
      toc[:children].push(book_toc(child_book))
    end

    book.pages.each do |page|
      toc[:children].push({id: page.id, title: page.title, type: 'page'})
    end
  end

end