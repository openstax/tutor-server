class CourseContent::GetCourseBooks
  lev_routine

  protected

  def exec(course:)
    outputs[:course_books] = CourseContent::Models::CourseBook.where(course: course.id)
    book_ids = outputs.course_books.collect(&:entity_book_id)
    outputs[:books] = Entity::Book.find(book_ids)
  end
end
