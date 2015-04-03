class Content::GetBookParts
  lev_routine express_output: :book_parts

  protected
  def exec(course_books:)
    outputs[:book_parts] = Content::Models::BookPart.where(
      entity_book_id: course_books.collect(&:entity_book_id)
    )
  end
end
