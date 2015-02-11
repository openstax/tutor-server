require 'rails_helper'

RSpec.describe ImportBook, :type => :routine do
  cnx_book_id = '031da8d3-b525-429c-80cf-6c8ed997733a'

  # Recursively tests the given book and its children
  def test_book(book)
    expect(book).to be_persisted
    expect(book.title).not_to be_blank
    expect(book.child_books.to_a + book.pages.to_a).not_to be_empty

    book.child_books.each do |cb|
      next if cb == book
      test_book(cb)
    end

    book.pages.each do |page|
      expect(page).to be_persisted
      expect(page.title).not_to be_blank
    end
  end

  it 'creates a new Book structure and Pages and sets their attributes' do
    result = nil
    expect {
      result = ImportBook.call(cnx_book_id)
    }.to change{ Book.count }.by(35)
    expect(result.errors).to be_empty

    test_book(result.outputs[:book])
  end
end
