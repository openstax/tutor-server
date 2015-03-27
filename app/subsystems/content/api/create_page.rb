class Content::Api::CreatePage

  lev_routine

  protected

  def exec(url:, title:, content:, book_part:, path:)
    page = Content::Models::Page.create(url: url,
                                title: title,
                                content: content,
                                book_part: book_part,
                                path: path)
    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end

end
