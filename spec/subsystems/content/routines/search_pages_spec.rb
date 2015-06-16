require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::Routines::SearchPages, type: :routine, speed: :slow, vcr: VCR_OPTS do

  let!(:cnx_book_hash) { { id: '93e2b09d-261c-4007-a987-0b3062fe154b' } }
  let!(:book)          { OpenStax::Cnx::V1::Book.new(cnx_book_hash) }

  it 'can search imported pages' do
    Content::ImportBook.call(cnx_book: book)

    url = Content::Models::Page.first.url
    pages = Content::Routines::SearchPages.call(url: url).outputs.items
    expect(pages.length).to eq 1
    expect(pages.first.url).to eq url

    lo = 'k12phys-ch04-s01-lo01'
    pages = Content::Routines::SearchPages.call(tag: lo).outputs.items
    expect(pages.length).to eq 1
    page = pages.first
    tags = page.page_tags.collect{|et| et.tag.value}
    expect(tags).to include(lo)
    parser = OpenStax::Cnx::V1::Page.new(content: page.content)
    expect(parser.los).to include(lo)
  end

end
