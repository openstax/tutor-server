class Content::VisitBook

  lev_routine

  protected

  def exec(book:, visitor_names:)

    visitor_names = [visitor_names].flatten

    # Map the visitor name to an actual visitor class

    visitors = visitor_names.collect do |name|
      case name.to_s
      when 'toc'
        outputs[:toc] = Content::Models::TocVisitor.new
      when 'exercises'
        outputs[:exercises] = Content::Models::ExerciseVisitor.new
      end
    end

    # Be friendly to either Entity::Books or their IDs

    book_id = book.is_a?(Integer) ? book : book.id

    # Get the root book part and kick off the visiting

    root_book_part = Content::Models::BookPart.root_for(book_id: book_id)
    visit_book_part(root_book_part, visitors)

    # We've temporarily stored the visitor objects in the outputs
    # structure for convenience.  Now iterate back through them
    # replace them with their visited output.

    visitor_names.each do |name|
      outputs[name] = outputs[name].output
    end

    # If there is just one visitor, enable express output

    if visitor_names.count == 1
      outputs[:visit_book] = outputs[visitor_names.first]
    end
  end

  # Instead of dirtying up the BookPart and Page classes, put the
  # visitation methods here.

  def visit_book_part(book_part, visitors)

    # Let visitors define what should be included in queries of pages and
    # book parts (to be more efficient in our querying)

    child_book_part_includes = []
    page_includes = []

    visitors.each do |visitor|
      visitor.visit_book_part(book_part)

      child_book_part_includes.push(visitor.book_part_includes)
      page_includes.push(visitor.page_includes)
    end

    # Tell visitors to move down a level if they are tracking levels,
    # then handle the contents at that next level (pages and child book parts)

    visitors.each{|visitor| visitor.descend}

    book_part.pages.includes(page_includes.uniq).each do |page|
      visit_page(page, visitors)
    end

    book_part.child_book_parts.includes(child_book_part_includes.uniq).each do |child_book_part|
      visit_book_part(child_book_part, visitors)
    end

    # Tell visitors to move up a level (we just finished going down a level)

    visitors.each{|visitor| visitor.ascend}
  end

  def visit_page(page, visitors)
    visitors.each do |visitor|
      visitor.visit_page(page)
    end
  end

end
