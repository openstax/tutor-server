require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Book, type: :external, vcr: VCR_OPTS do

  cnx_book_id = '93e2b09d-261c-4007-a987-0b3062fe154b'

  let(:expected_book_url) {
    'https://archive-staging-tutor.cnx.org/contents/93e2b09d-261c-4007-a987-0b3062fe154b'
  }

  it "provides info about the book with the given id" do
    book = OpenStax::Cnx::V1::Book.new(id: cnx_book_id)
    expect(book.id).to eq cnx_book_id
    expect(book.hash).not_to be_blank
    expect(book.url).to eq expected_book_url
    expect(book.uuid).to eq '93e2b09d-261c-4007-a987-0b3062fe154b'
    expect(book.version).to eq '3.6'
    expect(book.title).to eq 'Physics'
    expect(book.tree).not_to be_nil
    expect(book.root_book_part).to be_a OpenStax::Cnx::V1::BookPart
  end

end
