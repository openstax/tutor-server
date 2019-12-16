require 'rails_helper'

RSpec.describe Api::V1::BookTocRepresenter, type: :representer do
  let(:book) { { id: 1,
                 cnx_id: '123abc',
                 short_id: 'shorty',
                 uuid: 'uuid',
                 title: 'Good book',
                 type: 'foo',
                 archive_url: 'archive',
                 webview_url: 'webview',
                 chapter_section: [4, 1] } }

  subject(:represented) { described_class.new(Hashie::Mash.new(book)).to_hash }

  it 'works on the happy path' do
    expect(represented['type']).to eq('part')
    expect(represented['short_id']).to eq 'shorty'
    expect(represented['uuid']).to eq 'uuid'
    expect(represented['archive_url']).to eq 'archive'
    expect(represented['webview_url']).to eq 'webview'
  end
end
