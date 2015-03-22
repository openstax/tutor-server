module OpenStax::Cnx::V1::BookVisitor

  def pre_order_visit(elem:, depth:)
    case elem
    when OpenStax::Cnx::V1::Book
      pre_order_visit_book(book: elem, depth: depth)
    when OpenStax::Cnx::V1::BookPart
      pre_order_visit_book_part(book_part: elem, depth: depth)
    when OpenStax::Cnx::V1::Page
      pre_order_visit_page(page: elem, depth: depth)
    when OpenStax::Cnx::V1::Fragment::Text
      pre_order_visit_fragment_text(fragment_text: elem, depth: depth)
    when OpenStax::Cnx::V1::Fragment::Exercise
      pre_order_visit_fragment_exercise(fragment_exercise: elem, depth: depth)
    end
  end

  def visit(elem:, depth:)
    case elem
    when OpenStax::Cnx::V1::Book
      visit_book(book: elem, depth: depth)
    when OpenStax::Cnx::V1::BookPart
      visit_book_part(book_part: elem, depth: depth)
    when OpenStax::Cnx::V1::Page
      visit_page(page: elem, depth: depth)
    when OpenStax::Cnx::V1::Fragment::Text
      visit_fragment_text(fragment_text: elem, depth: depth)
    when OpenStax::Cnx::V1::Fragment::Exercise
      visit_fragment_exercise(fragment_exercise: elem, depth: depth)
    end
  end

  def post_order_visit(elem:, depth:)
    case elem
    when OpenStax::Cnx::V1::Book
      post_order_visit_book(book: elem, depth: depth)
    when OpenStax::Cnx::V1::BookPart
      post_order_visit_book_part(book_part: elem, depth: depth)
    when OpenStax::Cnx::V1::Page
      post_order_visit_page(page: elem, depth: depth)
    when OpenStax::Cnx::V1::Fragment::Text
      post_order_visit_fragment_text(fragment_text: elem, depth: depth)
    when OpenStax::Cnx::V1::Fragment::Exercise
      post_order_visit_fragment_exercise(fragment_exercise: elem, depth: depth)
    end
  end

  def pre_order_visit_book(book:, depth:); end
  def pre_order_visit_book_part(book_part:, depth:); end
  def pre_order_visit_page(page:, depth:); end
  def pre_order_visit_fragment_text(fragment_text:, depth:); end
  def pre_order_visit_fragment_exercise(fragment_exercise:, depth:); end
  def visit_book(book:, depth:); end
  def visit_book_part(book_part:, depth:); end
  def visit_page(page:, depth:); end
  def visit_fragment_text(fragment_text:, depth:); end
  def visit_fragment_exercise(fragment_exercise:, depth:); end
  def post_order_visit_book(book:, depth:); end
  def post_order_visit_book_part(book_part:, depth:); end
  def post_order_visit_page(page:, depth:); end
  def post_order_visit_fragment_text(fragment_text:, depth:); end
  def post_order_visit_fragment_exercise(fragment_exercise:, depth:); end

end
