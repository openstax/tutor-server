class Content::TocVisitor < Content::BookVisitor

  def initialize
    @toc = {}
    @stack = [@toc]
    @last_children = nil
  end

  def visit(item)
    item.is_a?(Content::BookPart) ? visit_book_part(item) : visit_page(item)
  end

  def visit_book_part(book_part)
    data = {
      id: book_part.id,
      title: book_part.title,
      type: 'part',
      children: []
    }

    if top_of_stack == @toc
      top_of_stack.merge!(data)
    else
      top_of_stack.push(data)
    end

    @last_children = data[:children]
  end

  def visit_page(page)
    top_of_stack.push({
      id: page.id, 
      title: page.title, 
      type: 'page'
    })
  end

  def descend
    @stack.push(@last_children)
  end

  def ascend
    @stack.pop
  end

  def top_of_stack
    @stack.last
  end

  def output
    @toc
  end

end