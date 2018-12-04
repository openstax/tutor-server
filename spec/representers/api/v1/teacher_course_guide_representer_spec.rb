require 'rails_helper'

RSpec.describe Api::V1::TeacherCourseGuideRepresenter, type: :representer do
  # TeacherCourseGuideRepresenter expects an array input because
  # GetCourseGuide returns an array of hashes
  # note the `guide` variable assignments

  it 'uses the title property' do
    guide = [Hashie::Mash.new({ title: 'Hello' })]
    decorated = described_class.new(guide).to_hash.first
    expect(decorated['title']).to eq('Hello')
  end

  it 'casts page_ids to strings' do
    guide = [Hashie::Mash.new({ title: 'Hello', page_ids: [1, 2] })]
    decorated = described_class.new(guide).to_hash.first
    expect(decorated['page_ids']).to eq(['1', '2'])
  end

  it 'recurses children with the child representer' do
    guide = [
      Hashie::Mash.new(
        {
          children: [
            {
              title: 'my cool title',
              book_location: [1, 4],
              baked_book_location: [1, 4],
              student_count: 5,
              questions_answered_count: 25,
              clue: {
                minimum: 0.7,
                most_likely: 0.89,
                maximum: 0.9,
                is_real: true
              },
              page_ids: [4, 5, 6]
            }
          ]
        }
      )
    ]

    decorated = described_class.new(guide).to_hash.first

    expect(decorated['children']).to eq(
      [
        {
          title: 'my cool title',
          chapter_section: [1, 4],
          baked_chapter_section: [1, 4],
          student_count: 5,
          questions_answered_count: 25,
          clue: {
            minimum: 0.7,
            most_likely: 0.89,
            maximum: 0.9,
            is_real: true
          },
          page_ids: ['4', '5', '6']
        }.deep_stringify_keys
      ]
    )
  end
end
