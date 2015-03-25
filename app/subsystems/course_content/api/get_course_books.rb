class CourseContent::Api::GetCourseBooks
  lev_routine

  protected

  def exec(course:)
    book_ids = CourseContent::CourseBook.where(course: course.id)
                                        .select(:entity_book_id)
                                        .collect{|cb| cb.entity_book_id}
    outputs[:books] = Entity::Book.find(book_ids)
  end
end
