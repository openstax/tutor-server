class Content::CreatePage
  lev_routine

  protected

  def exec(url:, content:, title:, book:nil, entity_book:nil)
    page = Content::Page.create(url: url,
                                content: content,
                                title: title,
                                book: book,
                                entity_book: entity_book)
    
    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end
end