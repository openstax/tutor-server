require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportBook, type: :routine, vcr: VCR_OPTS, speed: :slow do
  let(:ecosystem) { generate_mini_ecosystem }
  let(:book) { ecosystem.books.first }

  it 'creates a new Book structure and Pages and sets their attributes' do
    expect(ecosystem.id).not_to be_nil

    expect(book.id).not_to be_nil
    expect(book.url).to match(/contents\/405335a3-7cff-4df2-a9ad-29062a4af261/)
    expect(book.uuid).to eq '405335a3-7cff-4df2-a9ad-29062a4af261'
    expect(book.version).to match(/\d+.\d+/)

    book.chapters.each do |chapter|
      expect(chapter.title).not_to be_blank
    end

    book.pages.each do |page|
      expect(page.id).not_to be_nil
      expect(page.title).not_to be_blank
    end
  end

  it 'does not handle unbaked book_locations' do
    book.chapters.each do |chapter|
      expect(chapter.book_location).to eq []

      chapter.pages.each do |page|
        expect(page.book_location).to eq []
      end
    end
  end

end
