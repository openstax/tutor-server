class CourseContent::AddBookToCourse
  lev_routine

  protected

  def exec(course:, book:, remove_other_books: false)
    course.reload.course_books.destroy_all if remove_other_books
    course_book = CourseContent::Models::CourseBook.create(course: course, book: book)
    transfer_errors_from(course_book, {type: :verbatim}, true)
  end
end
