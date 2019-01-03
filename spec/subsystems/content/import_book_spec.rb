require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportBook, type: :routine, vcr: VCR_OPTS, speed: :medium do

  let(:phys_cnx_book) { OpenStax::Cnx::V1::Book.new(id: '93e2b09d-261c-4007-a987-0b3062fe154b') }
  let(:bio_cnx_book)  { OpenStax::Cnx::V1::Book.new(id: 'ccbc51fa-49f3-40bb-98d6-07a15a7ab6b7') }
  let(:bio_cc_book)   { OpenStax::Cnx::V1::Book.new(id: 'f10533ca-f803-490d-b935-88899941197f') }

  let(:ecosystem)     { FactoryBot.create :content_ecosystem }

  it 'creates a new Book structure and Pages and sets their attributes' do
    expect_any_instance_of(Content::Routines::PopulateExercisePools).to(
      receive(:call).and_wrap_original do |method, book:, save: true|
        expect(save).to eq true

        method.call book: book
      end
    )
    expect_any_instance_of(Content::Routines::UpdatePageContent).to(
      receive(:call).and_wrap_original do |method, book:, pages:, save: true|
        expect(save).to eq true

        method.call book: book, pages: pages
      end
    )
    expect(OpenStax::Biglearn::Api).to receive(:create_ecosystem)

    result = nil
    expect do
      result = Content::ImportBook.call(ecosystem: ecosystem, cnx_book: phys_cnx_book)
    end.to change{ Content::Models::Chapter.count }.by(4)
    expect(result.errors).to be_empty

    expect(ecosystem.id).not_to be_nil

    book = ecosystem.books.first
    expect(book.id).not_to be_nil
    expect(book.url).to eq phys_cnx_book.canonical_url
    expect(book.uuid).to eq phys_cnx_book.uuid
    expect(book.version).to eq phys_cnx_book.version

    book.chapters.each do |chapter|
      expect(chapter.id).not_to be_nil
      expect(chapter.title).not_to be_blank
    end

    book.pages.each do |page|
      expect(page.id).not_to be_nil
      expect(page.title).not_to be_blank
    end
  end

  it 'adds a book_location signifier according to subcol structure' do
    book_import = Content::ImportBook.call(ecosystem: ecosystem, cnx_book: phys_cnx_book)
    book = ecosystem.books.first

    book.chapters.each_with_index do |chapter, i|
      expect(chapter.book_location).to eq([i + 1])
      expect(chapter.baked_book_location).to eq []

      page_offset = 1
      chapter.pages.each_with_index do |page, pidx|
        page_offset = 0 if page.is_intro?
        expect(page.book_location).to eq([i + 1, pidx + page_offset])
        expect(page.baked_book_location).to eq []
      end
    end
  end

  it 'handles bio units book locations correctly' do
    Content::ImportBook.call(ecosystem: ecosystem, cnx_book: bio_cnx_book)
    book = ecosystem.books.first

    # Units are ignored

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

  it 'handles the bio cc book correctly' do
    OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents/') do
      Content::ImportBook.call(ecosystem: ecosystem, cnx_book: bio_cc_book)
    end
    book = ecosystem.books.first

    # shortId pulled in, webview_url good

    expect(book.short_id).to eq "8QUzyvgD"
    expect(book.archive_url).to eq "https://archive.cnx.org"
    expect(book.webview_url).to eq "https://cnx.org"
    expect(book.chapters.first.pages.first.short_id).to eq "rZudN6XP"

    # Units are ignored

    part = book.chapters.first
    expect(part.title).to eq "The Study of Life"
    expect(part.book_location).to eq [1]
    expect(part.baked_book_location).to eq []

    page = part.pages.first
    expect(page.title).to eq "Sample module 1"
    expect(page.book_location).to eq [1, 1]
    expect(page.baked_book_location).to eq []

    page = part.pages.second
    expect(page.title).to eq "The Science of Biology"
    expect(page.book_location).to eq [1, 2]
    expect(page.baked_book_location).to eq []

    # Jump to 3rd chapter

    part = book.chapters.third
    expect(part.title).to eq "Cell Structure"
    expect(part.book_location).to eq [3]
    expect(part.baked_book_location).to eq []

    page = part.pages.first
    expect(page.title).to eq "Sample module 3"
    expect(page.book_location).to eq [3, 1]
    expect(page.baked_book_location).to eq []

    page = part.pages.second
    expect(page.title).to eq "Studying Cells"
    expect(page.book_location).to eq [3, 2]
    expect(page.baked_book_location).to eq []
  end
end
