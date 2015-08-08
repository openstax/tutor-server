require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportBook, type: :routine, speed: :slow, vcr: VCR_OPTS do

  # Store version differences in this hash
  let!(:phys_cnx_book) { OpenStax::Cnx::V1::Book.new(id: '93e2b09d-261c-4007-a987-0b3062fe154b') }
  let!(:bio_cnx_book) { OpenStax::Cnx::V1::Book.new(id: 'ccbc51fa-49f3-40bb-98d6-07a15a7ab6b7') }

  let!(:ecosystem) { Ecosystem::Ecosystem.create! }

  before(:each)          { OpenStax::Biglearn::V1.use_fake_client }
  let!(:biglearn_client) { OpenStax::Biglearn::V1.fake_client }

  it 'creates a new Book structure and Pages and sets their attributes' do
    result = nil
    expect {
      result = Content::ImportBook.call(ecosystem: ecosystem, cnx_book: phys_cnx_book)
    }.to change{ Content::Models::Chapter.count }.by(4)
    expect(result.errors).to be_empty

    book = ecosystem.books.first
    expect(book.url).to eq phys_cnx_book.url
    expect(book.uuid).to eq phys_cnx_book.uuid
    expect(book.version).to eq phys_cnx_book.version

    book.chapters.each do |chapter|
      expect(chapter).to be_persisted
      expect(chapter.title).not_to be_blank
    end

    book.pages.each do |page|
      expect(page).to be_persisted
      expect(page.title).not_to be_blank
    end

    expect(biglearn_client.store_exercises_copy).to_not be_empty
  end

  it 'adds a book_location signifier according to subcol structure' do
    book_import = Content::ImportBook.call(ecosystem: ecosystem, cnx_book: phys_cnx_book)
    book = ecosystem.books.first

    chapters.each_with_index do |chapter, i|
      expect(chapter.book_location).to eq([i + 1])

      page_offset = 1
      chapter.pages.each_with_index do |page, pidx|
        page_offset = 0 if page.is_intro?
        expect(page.book_location).to eq([i + 1, pidx + page_offset])
      end
    end
  end

  it 'handles bio units book locations correctly' do
    Content::ImportBook.call(ecosystem: ecosystem, cnx_book: bio_cnx_book)
    book = ecosystem.books.first

    # The first child should be a chapter not a Unit

    part = book.chapters.first
    expect(part.title).to eq "The Study of Life"
    expect(part.book_location).to eq [1]

    page = book.chapters.first.pages.first
    expect(page.title).to eq "Introduction"
    expect(page.book_location).to eq [1, 0]

    # Jump to 3rd chapter

    part = book.chapters.third
    expect(part.title).to eq "Biological Macromolecules"
    expect(part.book_location).to eq [3]

    # The second page of that chapter

    page = book.chapters.third.pages.second
    expect(page.title).to eq "Macromolecules"
    expect(page.book_location).to eq [3,1]

    # Jump to 6th chapter (getting us into 2nd unit)

    part = book.chapters[5]
    expect(part.title).to eq "Metabolism"
    expect(part.book_location).to eq [6]
  end

end
