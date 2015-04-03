class Domain::GetCourseBooks
  lev_routine express_output: :book_parts

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::GetBookParts,
    translations: { outputs: { type: :verbatim } },
    as: :get_book_parts

  protected
  def exec(course:)
    run(:get_course_books, course: course)
    run(:get_book_parts, course_books: outputs.course_books)
  end
end
