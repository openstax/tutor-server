class Admin::BooksController < Admin::BaseController
  def index
    @books = Content::ListBooks[]
  end
end
