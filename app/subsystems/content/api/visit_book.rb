class Content::Api::VisitBook

  lev_routine

  protected

  def exec(book:, visitor_names:)
    visitors = visitor_names.collect do |name|
      case name.to_s
      when 'toc'
        outputs[:toc] = Content::TocVisitor.new
      when 'exercises'
        raise NotYetImplemented
      end
    end

    book_id = book.is_a?(Integer) ? book : book.id

    root_book_part = Content::BookPart.root_for(book_id: book_id)
    root_book_part.visit(visitors)

    visitor_names.each do |name|
      outputs[name] = outputs[name].output
    end
  end

end