# Visits a book with the specified visitors
#
# Parameters:
#   book: either an Entity::Models::Book or its ID
#   visitor_names: an array of strings or symbols that can include:
#     :toc - returns a table of contents
#     :exercises - returns all exercises in the book
#     :pages - returns page metadata
#
class Content::VisitBook
  lev_routine

  uses_routine Content::VisitBookPart,
               as: :visit,
               translations: { outputs: { map: {
                 visit_book_part: :visit_book
               } } }

  protected

  def exec(book:, visitor_names:)
    book_id = get_book_id(book)

    root_book_part = Content::Models::BookPart.root_for(book_id: book_id)

    # Kick off the recursive visitation at the root
    run(:visit, book_part: root_book_part, visitor_names: visitor_names)
  end

  private

  def get_book_id(book)
    book.is_a?(Integer) ? book : book.id
  end
end
