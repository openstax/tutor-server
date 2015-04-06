class Content::GetBookParts
  lev_routine express_output: :book_parts

  protected
  def exec(books:)
    outputs[:book_parts] = Content::Models::BookPart.where(
      entity_book_id: books.collect(&:id)
    )
  end
end
