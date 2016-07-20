require 'rails_helper'

RSpec.describe Api::V1::Courses::Cc::Teacher::PageRepresenter, type: :representer do
  let(:page)          {
    Hashie::Mash.new({
      id: 42,
      title: 'A page',
      uuid: 'uuid',
      version: 'version',
      book_location: [42, 42],
      completed: 0,
      in_progress: 1,
      not_started: 2,
      original_performance: 1.0,
      spaced_practice_performance: 0.5
    })
  }

  let(:representation) { described_class.new(page).as_json }

  it 'represents page stats' do
    expect(representation['id']).to eq '42'
    expect(representation['title']).to eq 'A page'
    expect(representation['uuid']).to eq 'uuid'
    expect(representation['version']).to eq 'version'
    expect(representation['chapter_section']).to eq [42, 42]
    expect(representation['completed']).to eq 0
    expect(representation['in_progress']).to eq 1
    expect(representation['not_started']).to eq 2
    expect(representation['original_performance']).to eq 1.0
    expect(representation['spaced_practice_performance']).to eq 0.5
  end
end
