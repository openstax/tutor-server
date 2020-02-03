require 'rails_helper'

RSpec.describe Api::V1::BookTocsRepresenter, type: :representer do
  let(:book) do
    {
      id: 1,
      cnx_id: '123abc',
      short_id: 'shorty',
      uuid: 'uuid',
      title: 'Good book',
      type: 'Book',
      archive_url: 'archive',
      webview_url: 'webview',
      chapter_section: [4, 1]
    }
  end

  subject(:represented) { described_class.new([ Hashie::Mash.new(book) ]).to_hash }

  it 'uses the BookTocRepresenter' do
    expect(represented.first['type']).to eq 'book'
    expect(represented.first['short_id']).to eq 'shorty'
    expect(represented.first['uuid']).to eq 'uuid'
    expect(represented.first['archive_url']).to eq 'archive'
    expect(represented.first['webview_url']).to eq 'webview'
  end
end
