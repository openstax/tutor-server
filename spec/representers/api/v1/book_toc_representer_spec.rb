require 'rails_helper'

RSpec.describe Api::V1::BookTocRepresenter, type: :representer do
  let(:book) { { id: 1,
                 cnx_id: '123abc',
                 title: 'Good book',
                 type: 'foo',
                 chapter_section: [4, 1] } }

  subject(:represented) { described_class.new(Hashie::Mash.new(book)).to_hash }

  it 'sets the type to part' do
    expect(represented['type']).to eq('part')
  end
end
