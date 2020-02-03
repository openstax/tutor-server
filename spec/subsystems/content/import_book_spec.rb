require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportBook, type: :routine, vcr: VCR_OPTS, speed: :medium do
  let(:phys_cnx_book) { OpenStax::Cnx::V1::Book.new(id: '93e2b09d-261c-4007-a987-0b3062fe154b') }
  let(:bio_cc_book)   { OpenStax::Cnx::V1::Book.new(id: 'f10533ca-f803-490d-b935-88899941197f') }

  let(:ecosystem)     { FactoryBot.create :content_ecosystem }

  it 'creates a new Book structure and Pages and sets their attributes' do
    expect_any_instance_of(Content::Routines::PopulateExercisePools).to(
      receive(:call).and_wrap_original do |method, book:, pages:, save: true|
        expect(save).to eq true

        method.call book: book, pages: pages
      end
    )
    expect_any_instance_of(Content::Routines::TransformAndCachePageContent).to(
      receive(:call).and_wrap_original do |method, book:, save: true|
        expect(save).to eq true

        method.call book: book
      end
    )
    expect(OpenStax::Biglearn::Api).to receive(:create_ecosystem)

    result = described_class.call(ecosystem: ecosystem, cnx_book: phys_cnx_book)
    expect(result.errors).to be_empty

    expect(ecosystem.id).not_to be_nil

    book = ecosystem.books.first
    expect(book.id).not_to be_nil
    expect(book.url).to eq phys_cnx_book.canonical_url
    expect(book.uuid).to eq phys_cnx_book.uuid
    expect(book.version).to eq phys_cnx_book.version

    book.chapters.each do |chapter|
      expect(chapter.title).not_to be_blank
    end

    book.pages.each do |page|
      expect(page.id).not_to be_nil
      expect(page.title).not_to be_blank
    end
  end

  it 'does not handle unbaked book_locations' do
    book_import = described_class.call(ecosystem: ecosystem, cnx_book: phys_cnx_book)
    book = ecosystem.books.first

    book.chapters.each do |chapter|
      expect(chapter.book_location).to eq []

      chapter.pages.each do |page|
        expect(page.book_location).to eq []
      end
    end
  end

  context 'with the bio book' do
    before(:all) do
      DatabaseCleaner.start

      bio_cnx_book = OpenStax::Cnx::V1::Book.new(id: 'ccbc51fa-49f3-40bb-98d6-07a15a7ab6b7')
      @ecosystem = FactoryBot.create :content_ecosystem
      VCR.use_cassette('Content_ImportBook/with_the_bio_book', VCR_OPTS) do
        described_class.call(ecosystem: @ecosystem, cnx_book: bio_cnx_book)
      end
    end

    after(:all)  { DatabaseCleaner.clean }

    it 'does not handle unbaked book_locations' do
      book = @ecosystem.books.first

      part = book.chapters.first
      expect(part.title).to eq 'The Study of Life'
      expect(part.book_location).to eq []

      page = book.chapters.first.pages.first
      expect(page.title).to eq 'Introduction'
      expect(page.book_location).to eq []

      # Jump to 3rd chapter

      part = book.chapters.third
      expect(part.title).to eq 'Biological Macromolecules'
      expect(part.book_location).to eq []

      # The second page of that chapter

      page = book.chapters.third.pages.second
      expect(page.title).to eq 'Macromolecules'
      expect(page.book_location).to eq []

      # Jump to 6th chapter (getting us into 2nd unit)

      part = book.chapters[5]
      expect(part.title).to eq 'Metabolism'
      expect(part.book_location).to eq []
    end

    it 'converts CNX links' do
      @ecosystem.pages.each do |page|
        page.send(:parser).root.css('[href]').each do |link|
          expect(link.attr('href')).not_to include 'cnx.org'
        end

        page.fragments.each do |fragment|
          Nokogiri::HTML.fragment(fragment.to_html).css('[href]').each do |link|
            expect(link.attr('href')).not_to include 'cnx.org'
          end
        end
      end
    end
  end

  context 'with the demo book' do
    before(:all) do
      DatabaseCleaner.start

      demo_cnx_book = OpenStax::Cnx::V1::Book.new(id: 'dc10e469-5816-411d-8ea3-39a9b0706a48')
      @ecosystem = FactoryBot.create :content_ecosystem
      VCR.use_cassette('Demo_Import/imports_the_demo_book', VCR_OPTS) do
        described_class.call(ecosystem: @ecosystem, cnx_book: demo_cnx_book)
      end
    end

    after(:all)  { DatabaseCleaner.clean }

    it 'handles baked book_locations' do
      book = @ecosystem.books.first

      expect(book.chapters.size).to eq 1
      expect(book.chapters.first.title).to eq 'Chapter 1'

      expect(book.as_toc.pages.map(&:book_location)).to eq [
        [1, 0], [1, 1], [1, 2], [1, 3], [1, 4]
      ]
      expect(book.as_toc.pages.map(&:title)).to eq [
        'Introduction',
        'Douglass struggles toward literacy',
        'Douglass struggles against slavery’s injustice',
        'Douglass promotes dignity',
        'Confrontation seeking righteousness'
      ]
    end

    it 'converts CNX links' do
      @ecosystem.pages.each do |page|
        page.send(:parser).root.css('[href]').each do |link|
          expect(link.attr('href')).not_to include 'cnx.org'
        end

        page.fragments.each do |fragment|
          Nokogiri::HTML.fragment(fragment.to_html).css('[href]').each do |link|
            expect(link.attr('href')).not_to include 'cnx.org'
          end
        end
      end
    end
  end
end
