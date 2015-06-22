require 'rails_helper'

RSpec.describe Api::V1::CourseGuideRepresenter do
  it 'has a title' do
    guide = Hashie::Mash.new({ title: 'Hello' })

    decorated = described_class.new(guide)

    expect(decorated.to_hash['title']).to eq('Hello')
  end

  it 'has page ids' do
    guide = Hashie::Mash.new({ title: 'Hello', page_ids: ['1', '2'] })

    decorated = described_class.new(guide)

    expect(decorated.to_hash['page_ids']).to eq(['1', '2'])
  end

  it 'has children' do
    guide = Hashie::Mash.new({ title: 'Hello',
                               page_ids: ['1', '2'],
                               children: ['anything?'] })

    decorated = described_class.new(guide)

    expect(decorated.to_hash['children']).to eq(%w(anything?))
  end
end
