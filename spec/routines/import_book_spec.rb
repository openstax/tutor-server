require 'rails_helper'

RSpec.describe ImportBook, :type => :routine do
  CNX_BOOK_ID = '031da8d3-b525-429c-80cf-6c8ed997733a'

  it 'creates a new Book with Chapters and Pages and sets their titles' do
    result = nil
    expect {
      result = ImportBook.call(CNX_BOOK_ID)
    }.to change{ Book.count }.by(1)
    expect(result.errors).to be_empty

    book = result.outputs[:book]
    expect(book).to be_persisted
    expect(book.title).not_to be_blank
    expect(book.chapters).not_to be_empty
    book.chapters.each do |chapter|
      expect(chapter).to be_persisted
      expect(chapter.title).not_to be_blank
      pages = chapter.pages
      expect(pages).not_to be_empty
      pages.each do |page|
        expect(page).to be_persisted
        expect(page.title).not_to be_blank
      end
    end
  end
end
