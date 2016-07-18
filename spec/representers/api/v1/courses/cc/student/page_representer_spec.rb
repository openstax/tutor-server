require 'rails_helper'

RSpec.describe Api::V1::Courses::Cc::Student::PageRepresenter, type: :representer do
  let(:worked_at_time) { Time.current }
  let(:page)           {
    Hashie::Mash.new({
      id: 42,
      title: 'A page',
      uuid: 'uuid',
      version: 'version',
      book_location: [42, 42],
      last_worked_at: worked_at_time,
      exercises: []
    })
  }

  let(:representation) { described_class.new(page).as_json }

  it 'represents page stats' do
    expect(representation['id']).to eq '42'
    expect(representation['title']).to eq 'A page'
    expect(representation['uuid']).to eq 'uuid'
    expect(representation['version']).to eq 'version'
    expect(representation['chapter_section']).to eq [42, 42]
    expect(representation['last_worked_at']).to eq DateTimeUtilities.to_api_s(worked_at_time)
    expect(representation['exercises']).to eq []
  end
end
