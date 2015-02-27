class Content::Api::GetBookToc

  lev_routine

  protected

  def exec(book_id:)
    root_book_part = Content::BookPart.find(entity_book_id: book_id)
    # Quick and dirty implementation (cache this stuff later)
    outputs[:toc] = book_part_toc(root_book_part)
  end

  def book_part_toc(book_part)
    toc = {}

    toc[:id] = book_part.id
    toc[:title] = book_part.title
    toc[:type] = 'part'
    toc[:children] = []

    book_part.child_book_parts.each do |child_book_part|
      toc[:children].push(book_part_toc(child_book_part))
    end

    book_part.pages.each do |page|
      toc[:children].push({id: page.id, title: page.title, type: 'page'})
    end
  end

end