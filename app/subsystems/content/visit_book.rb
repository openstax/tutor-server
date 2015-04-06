class Content::VisitBook
  lev_routine

  protected
  def exec(book:, visitor_names:)
    visitor_names = [visitor_names].flatten
    visitors = map_visitor_names_to_visitors(visitor_names)

    visit_root_book_part(book, visitors)
    replace_outputs_with_visited_output(visitor_names)
    enable_express_output_for_single_visitor(visitor_names)
  end

  private
  def visit_book_part(book_part, visitors)
    child_book_part_includes, page_includes = set_visitor_defined_includes(book_part,
                                                                           visitors)

    visitors.each(&:descend)
    visit_pages(book_part, page_includes, visitors)
    visit_book_parts(book_part, child_book_part_includes, visitors)
    visitors.each(&:ascend)
  end

  def visit_page(page, visitors)
    visitors.each do |visitor|
      visitor.visit_page(page)
    end
  end

  def map_visitor_names_to_visitors(visitor_names)
    visitor_names.collect do |name|
      case name.to_s
      when 'toc'
        outputs[:toc] = Content::Models::TocVisitor.new
      when 'exercises'
        outputs[:exercises] = Content::Models::ExerciseVisitor.new
      when 'page_data'
        outputs[:page_data] = Content::Models::PageDataVisitor.new
      end
    end
  end

  def visit_root_book_part(book, visitors)
    book_id = get_book_id(book)
    root_book_part = Content::Models::BookPart.root_for(book_id: book_id)
    visit_book_part(root_book_part, visitors)
  end

  def get_book_id(book)
    book.is_a?(Integer) ? book : book.id
  end

  def replace_outputs_with_visited_output(visitor_names)
    visitor_names.each do |name|
      outputs[name] = outputs[name].output
    end
  end

  def enable_express_output_for_single_visitor(visitor_names)
    if visitor_names.count == 1
      outputs[:visit_book] = outputs[visitor_names.first]
    end
  end

  def set_visitor_defined_includes(book_part, visitors)
    child_book_part_includes = []
    page_includes = []

    visitors.each do |visitor|
      visitor.visit_book_part(book_part)
      child_book_part_includes.push(visitor.book_part_includes)
      page_includes.push(visitor.page_includes)
    end

    return child_book_part_includes, page_includes
  end

  def visit_pages(book_part, includes, visitors)
    book_part.pages.includes(includes.uniq).each do |page|
      visit_page(page, visitors)
    end
  end

  def visit_book_parts(book_part, includes, visitors)
    book_part.child_book_parts.includes(includes.uniq).each do |child_book_part|
      visit_book_part(child_book_part, visitors)
    end
  end
end
