class Content::CreatePage
  lev_routine

  protected

  def exec(url:, content:, title:, book_part: nil, book: nil)
    page = Content::Page.create(url: url,
                                content: content,
                                title: title,
                                book_part: book_part,
                                book: book)
    
    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end
end