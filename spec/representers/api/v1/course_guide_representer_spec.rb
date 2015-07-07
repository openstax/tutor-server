require 'rails_helper'

RSpec.describe Api::V1::CourseGuideRepresenter do
  it 'has a title' do
    guide = Hashie::Mash.new({ title: 'Hello' })
    decorated = described_class.new(guide)
    expect(decorated.to_hash['title']).to eq('Hello')
  end

  it 'has page ids' do
    guide = Hashie::Mash.new({ title: 'Hello', page_ids: [1, 2] })
    decorated = described_class.new(guide)
    expect(decorated.to_hash['page_ids']).to eq(['1', '2'])
  end

  it 'has children' do
    guide = Hashie::Mash.new({ children: [{ title: 'my cool title',
                                            chapter_section: [1, 4],
                                            questions_answered_count: 25,
                                            current_level: 0.89,
                                            practice_count: 3,
                                            page_ids: [4, 5, 6] }] })

    decorated = described_class.new(guide)

    expect(decorated.to_hash['children']).to eq([{
      'title' => 'my cool title',
      'chapter_section' => [1, 4],
      'questions_answered_count' => 25,
      'current_level' => 0.89,
      'practice_count' => 3,
      'page_ids' => ['4', '5', '6']
    }])
  end
end
