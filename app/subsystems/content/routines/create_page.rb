class Content::CreatePage
  lev_routine

  protected

  def exec(url:, content:, book:nil, path:'', title:)
    page = Content::Page.create(url: url,
                                content: content,
                                book: book,
                                path: path,
                                title: title)

    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end
end
