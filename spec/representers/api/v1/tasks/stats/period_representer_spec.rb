require 'rails_helper'

RSpec.describe Api::V1::Tasks::Stats::PeriodRepresenter, type: :representer do
  let(:stat) { { period_id: 1,
                 name: '1st period',
                 total_exercises_count: 20,
                 complete_exercises_count: 2,
                 correct_exercises_count: 1,
                 total_tasks_count: 32,
                 complete_tasks_count: 28,
                 partially_complete_tasks_count: 2,
                 current_pages: [{ id: 1,
                                   title: 'My page',
                                   student_count: 1,
                                   correct_count: 1,
                                   incorrect_count: 0,
                                   chapter_section: [1, 2],
                                   exercises: [],
                                   previous_attempt: nil }],
                 spaced_pages: [{ id: 2,
                                  title: 'Spaced page',
                                  student_count: 1,
                                  correct_count: 0,
                                  incorrect_count: 1,
                                  chapter_section: [1, 3],
                                  exercises: [],
                                  previous_attempt: nil }] } }

  subject(:represented) { described_class.new(Hashie::Mash.new(stat)).to_hash }

  it 'represents the stats' do
    expect(represented).to eq({
      'period_id' => '1',
      'name' => '1st period',
      'total_exercises_count' => 20,
      'complete_exercises_count' => 2,
      'correct_exercises_count' => 1,
      'total_tasks_count' => 32,
      'complete_tasks_count' => 28,
      'partially_complete_tasks_count' => 2,
      'current_pages' => [{
        'id' => '1',
        'title' => 'My page',
        'student_count' => 1,
        'correct_count' => 1,
        'incorrect_count' => 0,
        'chapter_section' => [1, 2],
        'exercises' => []
      }],
      'spaced_pages' => [{
        'id' => '2',
        'title' => 'Spaced page',
        'student_count' => 1,
        'correct_count' => 0,
        'incorrect_count' => 1,
        'chapter_section' => [1, 3],
        'exercises' => []
      }]
    })
  end
end
