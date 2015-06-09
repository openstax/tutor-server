class Content::Routines::CreatePage

  lev_routine

  protected

  def exec(url:, title:, content:, book_part:, chapter_section:, uuid:, version:)
    page = Content::Models::Page.create(url: url,
                                title: title,
                                content: content,
                                book_part: book_part,
                                chapter_section: chapter_section,
                                uuid: uuid,
                                version: version)
    transfer_errors_from(page, {type: :verbatim}, true)

    outputs[:page] = page
  end

end
