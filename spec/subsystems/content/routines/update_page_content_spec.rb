require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::UpdatePageContent, type: :routine, vcr: VCR_OPTS do

  let!(:book_part) { FactoryGirl.create :content_book_part }

  let!(:cnx_page_1) {
    OpenStax::Cnx::V1::Page.new({
      id: '102e9604-daa7-4a09-9f9e-232251d1a4ee@7',
      title: 'Physical Quantities and Units'
    })
  }

  let!(:cnx_page_2) {
    OpenStax::Cnx::V1::Page.new({
      id: '127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
      title: "Introduction to Electric Current, Resistance, and Ohm's Law"
    })
  }

  let!(:page_1) {
    OpenStax::Cnx::V1.with_archive_url(url: 'http://archive.cnx.org/contents/') do
      Content::Routines::ImportPage.call(cnx_page: cnx_page_1, book_part: book_part).outputs[:page]
    end
  }

  let!(:page_2) {
    OpenStax::Cnx::V1.with_archive_url(url: 'http://archive.cnx.org/contents/') do
      Content::Routines::ImportPage.call(cnx_page: cnx_page_2, book_part: book_part).outputs[:page]
    end
  }

  let!(:link_text) { [
    "Introduction to Electric Current, Resistance, and Ohm's Law",
    'Accuracy, Precision, and Significant Figures',
    'Appendix A'
  ] }

  let!(:before_hrefs) { [
    'https://archive.cnx.org/contents/127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
    'https://archive.cnx.org/contents/4bba6a1c-a0e6-45c0-988c-0d5c23425670@7',
    'https://archive.cnx.org/contents/aaf30a54-a356-4c5f-8c0d-2f55e4d20556@3'
  ] }

  let!(:after_hrefs) { [
    '127f63f7-d67f-4710-8625-2b1d4128ef6b@2',
    'https://archive.cnx.org/contents/4bba6a1c-a0e6-45c0-988c-0d5c23425670@7',
    'https://archive.cnx.org/contents/aaf30a54-a356-4c5f-8c0d-2f55e4d20556@3'
  ] }

  let!(:page_with_exercises) {
    cnx_page = OpenStax::Cnx::V1::Page.new({
      id: 'bbefeebe-61f3-47fc-8b51-0ccb8f1bb8cc@23',
      title: 'Carbon'
    })
    OpenStax::Cnx::V1.with_archive_url(url: 'https://archive-staging-tutor.cnx.org/contents/') do
      Content::Routines::ImportPage.call(cnx_page: cnx_page, book_part: book_part).outputs[:page]
    end
  }

  it 'updates page content links to relative url if the link points to the book' do
    doc = Nokogiri::HTML(page_1.content)

    link_text.each_with_index do |value, i|
      link = doc.xpath("//a[text()=\"#{value}\"]").first
      expect(link.attribute('href').value).to eq before_hrefs[i]
    end

    Content::Routines::UpdatePageContent.call(book_part: book_part)
    page_1.reload

    doc = Nokogiri::HTML(page_1.content)

    link_text.each_with_index do |value, i|
      link = doc.xpath("//a[text()=\"#{value}\"]").first
      expect(link.attribute('href').value).to eq after_hrefs[i]
    end
  end

  it 'updates exercise links to absolute urls' do
    doc = Nokogiri::HTML(page_with_exercises.content)

    expected_links = doc.xpath('//a[starts-with(@href, "#ost")]').collect do |link|
      link.attribute('href').value
    end

    # Remove the exercise linked to apbio-ch02-ex031
    Content::Models::Tag.find_by_value('apbio-ch02-ex031').exercises
      .destroy_all

    # Remove the tag for apbio-ch02-ex032
    Content::Models::Tag.find_by_value('apbio-ch02-ex032').destroy

    # Get the rest of the exercises
    tags = Content::Models::Tag.where { value.like 'apbio-ch02-ex0%' }
                               .order(:value)
                               .includes(:exercises)

    # replace the expected links with exercise urls
    # (there are exercises created for the links except there is 1 tag with no
    # exercises and one link that doesn't have a tag)
    tags.each_with_index do |tag, i|
      expected_links[i] = tag.exercises.first.url.gsub(/\/exercises\//, '/api/exercises/') unless tag.exercises.empty?
    end

    Content::Routines::UpdatePageContent.call(book_part: book_part)
    page_with_exercises.reload

    doc = Nokogiri::HTML(page_with_exercises.content)
    links = doc.xpath('//a[starts-with(@href, "#ost") or contains(@href, "exercises")]').collect do |link|
      link.attribute('href').value
    end

    expect(links).to eq expected_links
  end
end
