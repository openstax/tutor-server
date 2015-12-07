class Content::Routines::ImportBookPart
  lev_routine outputs: {
                chapters: :_self,
                pages: :_self,
                page_taggings: :_self,
                exercises: :_self
              },
              uses: [{ name: Content::Routines::ImportBookPart, as: :import_book_part },
                     { name: Content::Routines::ImportPage, as: :import_page }]

  protected
  # Imports and saves a Cnx::BookPart as a Content::Models::Book or Content::Models::BookPart
  # Returns the Content::Models::Book or Content::Models::BookPart object
  def exec(cnx_book_part:, book:, chapter_tracker: nil, save: true)
    chapter_tracker ||= ChapterTracker.new

    set(chapters: [], pages: [], page_taggings: [], exercises: [])

    if cnx_book_part.is_chapter? # Skip root/units
      chapter = Content::Models::Chapter.new(
        book: book,
        number: chapter_tracker.value,
        title: cnx_book_part.title,
        book_location: [chapter_tracker.value]
      )
      chapter.save if save
      transfer_errors_from(chapter, {type: :verbatim}, true)
      book.chapters << chapter
      result.chapters << chapter
      page_offset = cnx_book_part.parts.first.try(:is_intro?) ? 0 : 1

      cnx_book_part.parts.each_with_index do |part, index|
        raise "Unexpected class #{part.class}" unless part.is_a?(OpenStax::Cnx::V1::Page)

        import_page = run(:import_page, cnx_page: part,
                                        chapter: chapter,
                                        number: index + 1,
                                        book_location: [chapter_tracker.value,
                                                        index + page_offset],
                                        save: save)

        result.pages << import_page.page
        result.page_taggings += import_page.taggings
        result.exercises += import_page.exercises
      end

      chapter_tracker.advance!
    else
      cnx_book_part.parts.each do |part|
        # skip all the pages at the book level
        next if cnx_book_part.is_root && part.is_a?(OpenStax::Cnx::V1::Page)

        raise "Unexpected class #{part.class}" unless part.is_a?(OpenStax::Cnx::V1::BookPart)

        import_book_part = run(:import_book_part, cnx_book_part: part,
                                                  book: book,
                                                  chapter_tracker: chapter_tracker,
                                                  save: save)

        result.chapters += import_book_part.chapters
        result.pages += import_book_part.pages
        result.page_taggings += import_book_part.page_taggings
        result.exercises += import_book_part.exercises
      end
    end
  end

  class ChapterTracker
    def initialize
      @chapter = 1
    end

    def value
      @chapter
    end

    def advance!
      @chapter += 1
    end
  end
end
