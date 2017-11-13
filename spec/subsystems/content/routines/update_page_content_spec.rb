require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::UpdatePageContent, type: :routine, vcr: VCR_OPTS do

  let(:cnx_page_1) {
    OpenStax::Cnx::V1::Page.new({
      id: '102e9604-daa7-4a09-9f9e-232251d1a4ee@7',
      title: 'Physical Quantities and Units'
    })
  }

  let(:cnx_page_2) {
    OpenStax::Cnx::V1::Page.new({
      id: '127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
      title: "Introduction to Electric Current, Resistance, and Ohm's Law"
    })
  }

  let(:chapter_1)  { FactoryBot.create :content_chapter, book_location: [1] }
  let(:book)       { chapter_1.book }
  let(:chapter_20) { FactoryBot.create :content_chapter, book: book, book_location: [20] }

  let!(:page_1) do
    OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents/') do
      Content::Routines::ImportPage[
        cnx_page: cnx_page_1, chapter: chapter_1, book_location: [1, 2]
      ]
    end
  end
  let!(:page_2) do
    OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/contents/') do
      Content::Routines::ImportPage[
        cnx_page: cnx_page_2, chapter: chapter_20, book_location: [20, 0]
      ]
    end
  end

  let(:link_text) { [
    "Introduction to Electric Current, Resistance, and Ohm's Law",
    'Accuracy, Precision, and Significant Figures',
    'Appendix A'
  ] }

  let(:before_hrefs) { [
    'https://cnx.org/contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
    'https://cnx.org/contents/4bba6a1c-a0e6-45c0-988c-0d5c23425670@7',
    'https://cnx.org/contents/aaf30a54-a356-4c5f-8c0d-2f55e4d20556@3'
  ] }

  let(:after_hrefs) { [
    '20',
    'https://cnx.org/contents/4bba6a1c-a0e6-45c0-988c-0d5c23425670@7',
    'https://cnx.org/contents/aaf30a54-a356-4c5f-8c0d-2f55e4d20556@3'
  ] }

  it 'updates page content links to relative url if the link points to the book' do
    doc = Nokogiri::HTML(page_1.content)

    link_text.each_with_index do |value, i|
      link = doc.xpath("//a[text()=\"#{value}\"]").first
      expect(link.attribute('href').value).to eq before_hrefs[i]
    end

    pages = [page_1, page_2]
    Content::Routines::UpdatePageContent.call(pages: pages)
    pages.each(&:save!)

    doc = Nokogiri::HTML(page_1.reload.content)

    link_text.each_with_index do |value, i|
      link = doc.xpath("//a[text()=\"#{value}\"]").first
      expect(link.attribute('href').value).to eq after_hrefs[i]
    end
  end
end
