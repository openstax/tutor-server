class CourseContent::GetCourseBooks
  lev_routine express_output: :books

  protected

  def exec(course:)
    course_books = CourseContent::Models::CourseBook.where(course: course.id)
    book_ids = course_books.collect(&:entity_book_id)
    outputs[:books] = Entity::Book.find(book_ids)
  end
end
