class Content::Api::GetBookToc

  lev_routine

  protected

  def exec(book_id:)
    root_book_part = Content::BookPart.root_for(book_id: book_id)
    # Quick and dirty implementation (cache this stuff later)
    toc = book_part_toc(root_book_part)
    outputs[:toc] = toc[:children]
  end

  def book_part_toc(book_part)
    toc = {}

    toc[:id] = book_part.id
    toc[:title] = book_part.title
    toc[:type] = 'part'
    toc[:children] = []

    book_part.child_book_parts.each do |child_book_part|
      toc[:children].append(book_part_toc(child_book_part))
    end

    book_part.pages.each do |page|
      toc[:children].append({id: page.id, title: page.title, type: 'page'})
    end

    outputs[:toc] = toc
  end

end