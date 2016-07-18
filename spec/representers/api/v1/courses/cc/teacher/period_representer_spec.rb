require 'rails_helper'

RSpec.describe Api::V1::Courses::Cc::Teacher::PeriodRepresenter, type: :representer do
  let(:period)          {
    Hashie::Mash.new({
      id: 42,
      name: 'A period',
      chapters: []
    })
  }

  let(:representation) { described_class.new(period).as_json }

  it 'represents period stats' do
    expect(representation['id']).to eq '42'
    expect(representation['name']).to eq 'A period'
    expect(representation['chapters']).to eq []
  end
end
