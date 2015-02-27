class Content::CreatePage
  lev_routine

  protected

  def exec(url:,content:, book:nil, title:)
    page = Content::Page.create(url: url,
                                content: content,
                                book: book,
                                title: title)
    
    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end
end