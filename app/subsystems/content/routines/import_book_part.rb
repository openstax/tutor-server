class Content::Routines::ImportBookPart

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part

  uses_routine Content::Routines::ImportPage, as: :import_page

  protected

  # Imports and saves a Cnx::BookPart as a Content::BookPart
  # Returns the Content::BookPart object
  def exec(cnx_book_part:, parent_book_part: nil, book: nil)
    book_part = Content::Models::BookPart.create(
      book: book, parent_book_part: parent_book_part,
      title: cnx_book_part.title, chapter_section: cnx_book_part.chapter_section
    )

    parent_book_part.child_book_parts << book_part unless parent_book_part.nil?

    cnx_book_part.parts.each do |part|
      if part.is_a?(OpenStax::Cnx::V1::BookPart)
        child_book_part = run(:import_book_part, cnx_book_part: part,
                              parent_book_part: book_part).outputs.book_part
        book_part.child_book_parts << child_book_part
      elsif part.is_a?(OpenStax::Cnx::V1::Page)
        page = run(:import_page, cnx_page: part,
                   book_part: book_part).outputs.page
        book_part.pages << page
      else
        raise "Unknown class #{part.class}"
      end
    end

    outputs[:book_part] = book_part
  end

end
