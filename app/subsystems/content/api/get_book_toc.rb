class Content::Api::GetBookToc

  lev_routine

  protected

  def exec(entity_book_id:)
    book = Content::Book.find(entity_book_id: entity_book_id)
    
  end

end