## This class exists only to aid debugging.
class OpenStax::Cnx::V1::BookToStringVisitor
  include OpenStax::Cnx::V1::BookVisitor

  def initialize(initial_indent: 0, indent_increment: 2, field_indent: 5)
    @string = ''
    @initial_indent   = initial_indent
    @indent_increment = indent_increment
    @field_indent     = field_indent
  end

  def pre_order_visit_book(book:, depth:)
    add_elem(depth, "BOOK  id = #{book.id}")
  end

  def pre_order_visit_book_part(book_part:, depth:)
    add_elem(depth, "PART  title = #{book_part.title}")
  end

  def pre_order_visit_page(page:, depth:)
    add_elem(depth, "PAGE  id = #{page.id}")
    add_field(depth, "LOs = #{page.los}")
  end

  def pre_order_visit_fragment_text(fragment_text:, depth:)
    add_elem(depth, "TEXT  title = #{fragment_text.title}")
  end

  def pre_order_visit_fragment_exercise(fragment_exercise:, depth:)
    add_elem(depth, "EXERCISE  title = #{fragment_exercise.title}")
    add_field(depth, "embed_tag = #{fragment_exercise.embed_tag}")
  end

  def elem_spaces(depth)
    "#{' ' * @initial_indent}#{' ' * (depth*@indent_increment)}"
  end

  def field_spaces(depth)
    "#{elem_spaces(depth)}#{' ' * @field_indent}"
  end

  def add_elem(depth, text)
    @string << elem_spaces(depth)
    @string << text
    @string << "\n"
  end

  def add_field(depth, text)
    @string << field_spaces(depth)
    @string << text
    @string << "\n"
  end

  def to_s
    @string
  end
end
