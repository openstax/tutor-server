require 'rails_helper'

RSpec.describe Api::V1::Courses::Cc::Teacher::ChapterRepresenter, type: :representer do
  let(:chapter)          {
    Hashie::Mash.new({
      id: 42,
      title: 'A chapter',
      book_location: [42, 42],
      pages: []
    })
  }

  let(:representation) { described_class.new(chapter).as_json }

  it 'represents chapter stats' do
    expect(representation['id']).to eq '42'
    expect(representation['title']).to eq 'A chapter'
    expect(representation['chapter_section']).to eq [42, 42]
    expect(representation['pages']).to eq []
  end
end
