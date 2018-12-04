require 'rails_helper'

RSpec.describe Api::V1::PageTocRepresenter, type: :representer do
  let(:page) do
    {
      id: 1,
      cnx_id: '321cba',
      short_id: 'shorty',
      uuid: 'uuid',
      title: 'Neat page',
      type: 'baz',
      book_location: [4, 3],
      baked_book_location: [4, 3]
    }
  end

  subject(:represented) { described_class.new(Hashie::Mash.new(page)).to_hash }

  it 'renames book_location to chapter_section' do
    expect(represented['chapter_section']).to eq([4, 3])
  end

  it 'works on the happy path' do
    expect(represented['type']).to eq('page')
    expect(represented['short_id']).to eq 'shorty'
    expect(represented['uuid']).to eq 'uuid'
  end
end
