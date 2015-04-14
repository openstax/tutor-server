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
      fields: outputs.toc.from(1).map { |toc| translate_toc(toc) }
    }
  end

  def translate_toc(toc)
    translated = { id: toc.id,
                   title: toc.title,
                   unit: toc.path }
    merge_pages_for_toc_children(translated, toc.children)
    translated
  end

  def merge_pages_for_toc_children(hash, children)
    return unless (children || []).any?
    hash.merge!(pages: children.collect { |child| translate_toc(child) })
  end
end
