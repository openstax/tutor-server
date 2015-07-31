class CourseContent::GetCourseBooks
  lev_routine express_output: :books

  protected

  def exec(course:)
    course_books = CourseContent::Models::CourseBook.where(course: course.id)
    book_ids = course_books.collect(&:content_book_id)
    outputs[:books] = Content::Models::Book.find(book_ids)
  end
end
