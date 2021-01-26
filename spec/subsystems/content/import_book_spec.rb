require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportBook, type: :routine, vcr: VCR_OPTS, speed: :slow do
  let(:book) { @ecosystem.books.first }

  context 'with the phys book' do
    before(:all) do
      DatabaseCleaner.start

      @phys_cnx_book = OpenStax::Cnx::V1::Book.new(id: '93e2b09d-261c-4007-a987-0b3062fe154b')
      @ecosystem = FactoryBot.create :content_ecosystem
      VCR.use_cassette('Content_ImportBook/with_the_phys_book', VCR_OPTS) do
        described_class.call(ecosystem: @ecosystem, cnx_book: @phys_cnx_book)
      end
    end

    after(:all) { DatabaseCleaner.clean }

    it 'creates a new Book structure and Pages and sets their attributes' do
      expect(@ecosystem.id).not_to be_nil

      expect(book.id).not_to be_nil
      expect(book.url).to eq @phys_cnx_book.canonical_url
      expect(book.uuid).to eq @phys_cnx_book.uuid
      expect(book.version).to eq @phys_cnx_book.version

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

  context 'with the bio book' do
    before(:all) do
      DatabaseCleaner.start

      bio_cnx_book = OpenStax::Cnx::V1::Book.new(id: '6c322e32-9fb0-4c4d-a1d7-20c95c5c7af2')
      @ecosystem = FactoryBot.create :content_ecosystem
      OpenStax::Cnx::V1.with_archive_url('https://openstax.org/apps/archive/20201222.172624/contents') do
        OpenStax::Exercises::V1.use_fake_client do
          VCR.use_cassette('Content_ImportBook/with_the_bio_book', VCR_OPTS) do
            described_class.call(ecosystem: @ecosystem, cnx_book: bio_cnx_book)
          end
        end
      end
    end

    after(:all)  { DatabaseCleaner.clean }

    it 'handles units and baked book_locations' do
      book.units.each { |unit| expect(unit.book_location).to eq [] }
      book.chapters.each_with_index do |chapter, index|
        expect(chapter.book_location).to eq [index + 1]
      end

      chapter = book.chapters.first
      expect(book.units.first.chapters.first).to eq chapter
      expect(chapter.title).to match 'The Study of Life'
      expect(chapter.book_location).to eq [1]

      page = book.chapters.first.pages.first
      expect(page.title).to match 'Introduction'
      expect(page.book_location).to eq []

      # Jump to 3rd chapter
      chapter = book.chapters.third
      expect(book.units.first.chapters.third).to eq chapter
      expect(chapter.title).to match 'Biological Macromolecules'
      expect(chapter.book_location).to eq [3]

      # The second page of that chapter
      page = chapter.pages.second
      expect(page.title).to match 'Synthesis of Biological Macromolecules'
      expect(page.book_location).to eq [3, 1]

      # Jump to 6th chapter (getting us into 2nd unit)
      chapter = book.chapters[5]
      expect(book.units.second.chapters.third).to eq chapter
      expect(chapter.title).to match 'Metabolism'
      expect(chapter.book_location).to eq [6]
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
      expect(book.chapters.size).to eq 1
      expect(book.chapters.first.title).to match 'Chapter 1'

      expect(book.as_toc.pages.map(&:book_location)).to eq [ [], [1, 1], [1, 2], [1, 3], [1, 4] ]
      titles = [
        'Introduction',
        'Douglass struggles toward literacy',
        'Douglass struggles against slavery’s injustice',
        'Douglass promotes dignity',
        'Confrontation seeking righteousness'
      ]
      book.as_toc.pages.each_with_index do |page, index|
        expect(page.title).to match titles[index]
      end
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
