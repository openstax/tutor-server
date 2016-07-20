require 'rails_helper'
require 'vcr_helper'

RSpec.describe FetchAndImportBookAndCreateEcosystem, type: :routine, speed: :slow, vcr: VCR_OPTS do

  context 'tutor book' do
    let(:archive_url) { 'https://archive-staging-tutor.cnx.org/contents/' }
    let(:book_cnx_id) { '93e2b09d-261c-4007-a987-0b3062fe154b@4.4' }

    it 'imports books and exercises as ecosystems' do
      expect {
        described_class.call(archive_url: archive_url, book_cnx_id: book_cnx_id)
      }.to change { Content::Models::Ecosystem.count }.by(1)
    end

    it 'imports a book even if the book already exists' do
      FactoryGirl.create(:content_book,
                         title: 'Physics',
                         url: "#{archive_url}#{book_cnx_id}",
                         version: '4.4')

      expect {
        described_class.call(archive_url: archive_url, book_cnx_id: book_cnx_id)
      }.to change { Content::Models::Ecosystem.count }.by(1)
    end

    it 'imports a book with a different version' do
      FactoryGirl.create(:content_book,
                         title: 'Physics',
                         url: "#{archive_url}#{book_cnx_id}",
                         version: '4.4')

      expect {
        described_class.call(archive_url: archive_url, book_cnx_id: book_cnx_id.sub('@4.4', '@4.3'))
      }.to change { Content::Models::Ecosystem.count }.by(1)
    end
  end

  context 'cc book' do
    let(:archive_url) { 'https://archive.cnx.org/contents/' }
    let(:book_cnx_id) { 'f10533ca-f803-490d-b935-88899941197f@2.1' }

    it 'imports books and exercises as ecosystems' do
      expect {
        described_class.call(archive_url: archive_url, book_cnx_id: book_cnx_id)
      }.to change { Content::Models::Ecosystem.count }.by(1)
    end

    it 'imports a book even if the book already exists' do
      FactoryGirl.create(:content_book,
                         title: 'Derived copy of Biology',
                         url: "#{archive_url}#{book_cnx_id}",
                         version: '2.1')

      expect {
        described_class.call(archive_url: archive_url, book_cnx_id: book_cnx_id)
      }.to change { Content::Models::Ecosystem.count }.by(1)
    end

    it 'imports a book with a different version' do
      FactoryGirl.create(:content_book,
                         title: 'Derived copy of Biology',
                         url: "#{archive_url}#{book_cnx_id}",
                         version: '2.1')

      expect {
        described_class.call(archive_url: archive_url, book_cnx_id: book_cnx_id.sub('@2.1', '@1.1'))
      }.to change { Content::Models::Ecosystem.count }.by(1)
    end
  end

end
