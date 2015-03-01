class CourseContent::Api::AddBookToCourse
  lev_routine

  protected

  def exec(course:, book:)
    course_book = CourseContent::CourseBook.create(course: course, book: book)
    transfer_errors_from(course_book, {type: :verbatim}, true)
  end
end