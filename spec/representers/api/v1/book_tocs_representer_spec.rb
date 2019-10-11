require 'rails_helper'

RSpec.describe Api::V1::BookTocsRepresenter, type: :representer do
  it 'uses the BookTocRepresenter' do
    book_toc = { id: 1,
                 cnx_id: '123abc',
                 title: 'Physics 401',
                 type: 'foo',
                 chapter_section: [4, 1],
                 chapters: [{ id: 1,
                              title: 'Good chapter',
                              type: 'bar',
                              baked_book_location: [4, 2],
                              book: Hashie::Mash[is_collated: true],
                              pages: [{ id: 1,
                                        cnx_id: '321cba',
                                        title: 'Neat page',
                                        type: 'baz',
                                        chapter: Hashie::Mash[book: {
                                          is_collated: true
                                        }],
                                        baked_book_location: [4, 3] }] }] }

    representation = described_class.new([Hashie::Mash.new(book_toc)]).to_hash

    expect(representation).to eq(
      [{ "id" => "1",
         "cnx_id" => '123abc',
         "title" => 'Physics 401',
         "type" => 'part',
         "chapter_section" => [],
         "children" => [{ "id" => "1",
                          "title" => 'Good chapter',
                          "type" => 'part',
                          "chapter_section" => [4, 2],
                          "children" => [{ "id" => "1",
                                           "cnx_id" => '321cba',
                                           "title" => 'Neat page',
                                           "type" => 'page',
                                           "chapter_section" => [4, 3] }] }] }]
    )
  end
end
