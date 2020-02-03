require 'rails_helper'

RSpec.describe Api::V1::BookTocRepresenter, type: :representer do
  it 'represents a book as a table of contents' do
    book_toc = {
      id: 1,
      cnx_id: '123abc',
      title: 'Physics 401',
      type: 'Book',
      chapter_section: [4, 1],
      children: [
        {
          id: 1,
          title: 'Good chapter',
          type: 'Chapter',
          book_location: [4, 2],
          book: Hashie::Mash[is_collated: true],
          children: [
            {
              id: 1,
              cnx_id: '321cba',
              title: 'Neat page',
              type: 'Page',
              chapter: Hashie::Mash[book: { is_collated: true }],
              book_location: [4, 3]
            }
          ]
        }
      ]
    }

    representation = described_class.new(Hashie::Mash.new(book_toc)).to_hash

    expect(representation.deep_symbolize_keys).to eq(
      id: '1',
      cnx_id: '123abc',
      title: 'Physics 401',
      type: 'book',
      chapter_section: [],
      children: [
        {
          id: '1',
          title: 'Good chapter',
          type: 'chapter',
          chapter_section: [4, 2],
          children: [
            {
              id: '1',
              cnx_id: '321cba',
              title: 'Neat page',
              type: 'page',
              chapter_section: [4, 3]
            }
          ]
        }
      ]
    )
  end
end
