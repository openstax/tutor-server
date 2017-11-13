require 'rails_helper'

RSpec.describe Api::V1::EcosystemRepresenter, type: :representer do

  let(:book) { FactoryBot.create :content_book, title: 'Physics', version: '1' }

  subject(:represented) { described_class.new(book.ecosystem).to_hash }

  it 'can represent an ecosystem' do
    expect(represented).to eq({
      'id' => book.ecosystem.id,
      'comments' => book.ecosystem.comments,
      'books' => [{
        'id'      => book.id,
        'uuid'    => book.uuid,
        'title'   => book.title,
        'version' => book.version
      }]
    })
  end

end
