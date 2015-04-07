class Domain::GetUserCourseStats
  lev_routine express_output: :course_stats

  uses_routine CourseProfile::GetProfile,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_profile

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :get_book_toc

  protected
  def exec(user:, course:)
    run(:get_course_profile, course: course)
    run(:get_course_books, course: course)
    compile_course_stats
  end

  private
  def compile_course_stats
    outputs[:course_stats] = {
      title: outputs.profile.name,
      fields: collect_book_parts
    }
  end

  def collect_book_parts
    compile_course_books_toc
    book_parts = []
    outputs.book_toc.each do |book_toc|
      book_parts << transform_toc(book_toc)
      book_parts << transform_child_toc(book_toc)
    end
    book_parts.flatten
  end

  def compile_course_books_toc
    outputs[:book_toc] = []
    outputs.books.each do |book|
      outputs.book_toc << run(:get_book_toc, book: book, visitor_names: :toc).outputs.toc
    end
  end

  def transform_toc(book_toc)
    book_toc.collect do |toc|
      { id: toc.id,
        title: toc.title,
        number: toc.path,
        page_ids: toc.page_ids || [] }
    end
  end

  def transform_child_toc(book_toc)
    children = []
    book_toc.each do |toc|
      next unless toc.children
      children << transform_toc(toc.children)
      toc.children.each do |child_toc|
        children << transform_toc(child_toc.children)
      end
    end
    children.flatten
  end
end
