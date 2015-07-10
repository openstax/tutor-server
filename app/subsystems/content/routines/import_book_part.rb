class Content::Routines::ImportBookPart

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part

  uses_routine Content::Routines::ImportPage, as: :import_page

  protected

  # Imports and saves a Cnx::BookPart as a Content::BookPart
  # Returns the Content::BookPart object
  def exec(cnx_book_part:, parent_book_part: nil, book: nil, chapter_section: [])

    is_unit = !parent_book_part.nil? && !cnx_book_part.is_chapter?

    if is_unit
      # Skip units: don't make a book part, and remove a level of the chapter_section
      book_part = parent_book_part
      chapter_section.pop
    else
      book_part = Content::Models::BookPart.create(
        book: book, parent_book_part: parent_book_part,
        title: cnx_book_part.title, chapter_section: chapter_section
      )

      parent_book_part.child_book_parts << book_part unless parent_book_part.nil?
    end

    cnx_book_part.parts.each_with_index do |part, index|
      if part.is_a?(OpenStax::Cnx::V1::BookPart)
        run(:import_book_part,
            cnx_book_part: part,
            parent_book_part: book_part,
            chapter_section: chapter_section + [index + 1])
      elsif part.is_a?(OpenStax::Cnx::V1::Page)
        run(:import_page,
            cnx_page: part,
            book_part: book_part,
            chapter_section: chapter_section + [index])
      else
        raise "Unknown class #{part.class}"
      end
    end

    outputs[:book_part] = book_part
  end

end
