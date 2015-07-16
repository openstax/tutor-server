class Content::ListBooks
  lev_routine express_output: :books

  protected

  def exec
    root_book_parts = Content::Models::BookPart.roots.order(:title)
    outputs[:books] = root_book_parts.collect do |book_part|
      Hashie::Mash.new(
        id: book_part.entity_book_id,
        title: book_part.title,
        url: book_part.url,
        uuid: book_part.uuid,
        version: book_part.version
      )
    end
  end
end
