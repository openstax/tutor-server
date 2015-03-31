class CourseContent::GetCourseBooks
  lev_routine

  protected

  def exec(course:)
    book_ids = CourseContent::Models::CourseBook.where(course: course.id)
                                        .select(:entity_book_id)
                                        .collect{|cb| cb.entity_book_id}
    outputs[:books] = Entity::Models::Book.find(book_ids)
  end
end
