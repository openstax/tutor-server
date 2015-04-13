class Domain::GetUserCourseStats
  lev_routine express_output: :course_stats

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :get_book_toc

  protected
  def exec(user:, course:)
    run(:get_course_books, course: course)
    run(:get_book_toc, book: outputs.books.first, visitor_names: :toc)
    compile_course_stats
  end

  private
  def compile_course_stats
    outputs[:course_stats] = {
      title: outputs.toc.first.title,
      fields: collect_book_parts
    }
  end

  def collect_book_parts
    book_parts = []
    outputs.toc.from(1).each do |book_toc|
      book_parts << translate_toc(book_toc)
    end
    book_parts
  end

  def translate_toc(toc)
    translated = {
      id: toc.id,
      title: toc.title,
      unit: toc.path
    }

    if (toc.children || []).any?
      translated.merge!(pages: translate_children(toc.children))
    end

    translated
  end

  def translate_children(children)
    children.collect { |child_toc| translate_toc(child_toc) }
  end
end
