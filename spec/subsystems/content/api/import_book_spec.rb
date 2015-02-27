require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Api::ImportBook, :type => :routine,
                                    :vcr => VCR_OPTS,
                                    :speed => :slow do
  cnx_book_id = '031da8d3-b525-429c-80cf-6c8ed997733a'

  fixture_file = "spec/fixtures/#{cnx_book_id}/tree/contents.json"

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
      result = Content::Api::ImportBook.call(cnx_book_id)
    }.to change{ Book.count }.by(35)
    expect(result.errors).to be_empty

    book = result.outputs[:book]
    toc = open(fixture_file) { |f| f.read }
    expect(JSON.parse(book.content)).to eq JSON.parse(toc)
    test_book(book)
  end
end
