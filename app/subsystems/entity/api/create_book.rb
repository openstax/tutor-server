class Entity::CreateBook
  lev_routine

  protected

  def exec
    book = Entity::Book.create
    transfer_errors_from(book, {type: :verbatim}, true)
    outputs[:book] = book
  end
end
