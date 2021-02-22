require 'rails_helper'
require 'vcr_helper'

RSpec.describe OpenStax::Cnx::V1::Book, type: :external, vcr: VCR_OPTS do
  let(:cnx_book_id) { PopulateMiniEcosystem.cnx_book_hash[:id] }

  let(:expected_book_url) {
    "https://archive.cnx.org/contents/#{cnx_book_id}"
  }

  it "provides info about the book with the given id" do
    book = OpenStax::Cnx::V1::Book.new(id: cnx_book_id)
    expect(book.id).to eq cnx_book_id
    expect(book.hash).not_to be_blank
    expect(book.url).to eq expected_book_url
    expect(book.uuid).to eq cnx_book_id
    expect(book.version).to match /\d+.\d+/
    expect(book.title).to be_a(String)
    expect(book.tree).not_to be_nil
    expect(book.root_book_part).to be_a OpenStax::Cnx::V1::BookPart
  end
end
