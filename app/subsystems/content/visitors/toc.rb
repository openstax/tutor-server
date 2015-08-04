class Content::Visitors::Toc < Content::Visitors::Book

  def initialize
    @level_stack = []
  end

  def visit_book_part(book_part)
    data = {
      id: book_part.id,
      title: book_part.title,
      type: 'part',
      children: [],
      chapter_section: book_part.chapter_section
    }

    current_level.push(data)

    @one_level_down = data[:children]
  end

  def visit_page(page)
    current_level.push({
      id: page.id,
      title: page.title,
      type: 'page',
      cnx_id: page.cnx_id,
      chapter_section: page.chapter_section
    })
  end

  def descend
    @level_stack.push(@one_level_down)
  end

  def ascend
    @level_stack.pop
  end

  def current_level
    @level_stack.last || @level_stack
  end

  def output
    current_level
  end

end
