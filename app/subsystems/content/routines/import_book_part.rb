class Content::Routines::ImportBookPart

  lev_routine

  uses_routine Content::Routines::ImportBookPart, as: :import_book_part

  uses_routine Content::Routines::ImportPage, as: :import_page

  protected

  # Imports and saves a Cnx::BookPart as a Content::BookPart
  # Returns the Content::BookPart object
  def exec(cnx_book_part:, parent_book_part: nil, book:,
           chapter_section_tracker: nil, book_url: nil, uuid: nil, version: nil)

    chapter_section_tracker ||= ChapterSectionTracker.new

    if cnx_book_part.is_unit?(has_parent: parent_book_part.present?)
      # Skip units: don't make a book part
      book_part = parent_book_part
    else
      book_part = Content::Models::BookPart.create(
        book: book,
        parent_book_part: parent_book_part,
        title: cnx_book_part.title,
        chapter_section: chapter_section_tracker.value,
        url: book_url,
        uuid: uuid,
        version: version
      )

      parent_book_part.child_book_parts << book_part unless parent_book_part.nil?
    end

    cnx_book_part.parts.each_with_index do |part, index|
      if part.is_a?(OpenStax::Cnx::V1::BookPart)

        chapter_section_tracker.advance_chapter! unless part.is_unit?(has_parent: true)

        run(:import_book_part,
            cnx_book_part: part,
            parent_book_part: book_part,
            book: book,
            chapter_section_tracker: chapter_section_tracker)

      elsif part.is_a?(OpenStax::Cnx::V1::Page)

        chapter_section_tracker.advance_section!(page: part)

        run(:import_page,
            cnx_page: part,
            book_part: book_part,
            chapter_section: chapter_section_tracker.value)

      else
        raise "Unknown class #{part.class}"
      end
    end

    outputs[:book_part] = book_part
  end

  def is_unit?(parent_book_part, cnx_book_part)
    !parent_book_part.nil? && cnx_book_part.has_child_book_parts?
  end

  class ChapterSectionTracker
    def initialize
      @chapter = 0
      @section = nil
    end

    def value
      return []                   if starting_a_book?    # root value
      return [@chapter]           if starting_a_chapter? # chapter value
      return [@chapter, @section]                        # page value
    end

    def reset_section!(has_intro)
      # If has an intro, we want first page to be x.0; otherwise x.1.  Start
      # one below that goal
      @section = has_intro ? -1 : 0
    end

    def advance_chapter!
      @chapter += 1
      @section = nil
    end

    def advance_section!(page:)
      if starting_a_chapter?
        if page.is_intro?
          @section = 0
        else
          @section = 1
        end
      else
        @section += 1
      end
    end

    def starting_a_chapter?
      @section.nil?
    end

    def starting_a_book?
      0 == @chapter
    end
  end

end
