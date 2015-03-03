class Content::CreatePage
  lev_routine

  protected

  def exec(url:, content:, book:nil, book_part: nil, path:'', title:)
    page = Content::Page.create(url: url,
                                content: content,
                                title: title,
                                path: path,
                                book_part: book_part,
                                book: book)

    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end
end
