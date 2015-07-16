require 'rails_helper'

RSpec.describe Content::ListBooks, type: :routine do
  let!(:book_1_uuid) { '64e410d3-42a0-4e3e-af06-7ca547af06ee' }
  let!(:book_1) {
    FactoryGirl.create :content_book_part, contents: {
      title: 'My Book',
      uuid: book_1_uuid,
      version: '6'
    }
  }
  let!(:book_2) { FactoryGirl.create :content_book_part, :standard_contents_1 }

  it 'returns all the books' do
    books = Content::ListBooks[]
    expect(books).to eq([
      {
        'id' => book_2.entity_book_id,
        'title' => book_2.title,
        'url' => book_2.url,
        'uuid' => book_2.uuid,
        'version' => book_2.version
      },
      {
        'id' => book_1.entity_book_id,
        'title' => 'My Book',
        'url' => "https://archive.cnx.org/contents/#{book_1_uuid}@6",
        'uuid' => book_1_uuid,
        'version' => '6'
      }
    ])
  end
end
