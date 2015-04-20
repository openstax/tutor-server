class Content::Routines::CreatePage

  lev_routine

  protected

  def exec(url:, title:, content:, book_part:, chapter_section:)
    page = Content::Models::Page.create(url: url,
                                title: title,
                                content: content,
                                book_part: book_part,
                                chapter_section: chapter_section)
    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end

end
