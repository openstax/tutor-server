require 'rails_helper'

RSpec.describe Api::V1::PageTocRepresenter, type: :representer do
  let(:page) { { id: 1,
                 cnx_id: '321cba',
                 title: 'Neat page',
                 type: 'baz',
                 book_location: [4, 3] } }

  subject(:represented) { described_class.new(Hashie::Mash.new(page)).to_hash }

  it 'sets the type to page' do
    expect(represented['type']).to eq('page')
  end

  it 'renames book_location to chapter_section' do
    expect(represented['chapter_section']).to eq([4, 3])
  end
end
