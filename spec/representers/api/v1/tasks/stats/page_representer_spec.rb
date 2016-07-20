require 'rails_helper'

RSpec.describe Api::V1::Tasks::Stats::PageRepresenter, type: :representer do
  let(:page) {
    { id: 1,
      title: 'My page',
      student_count: 1,
      correct_count: 1,
      incorrect_count: 0,
      chapter_section: [1, 2],
      exercises: [{
        content: 'Cool content',
        question_stats: [{
          question_id: 'id42',
          answered_count: 1,
          answers: [{
            student_names: ['Jim', 'Jack'],
            free_response: 'Hello',
            answer_id: 1
          }] # skipped answer_stats, taken care of in exercise representer spec
        }]
      }],
      previous_attempt: {
        id: 1,
        title: 'My page',
        student_count: 1,
        correct_count: 0,
        incorrect_count: 1,
        chapter_section: [1, 2],
        exercises: [{
          content: 'Cool content',
          question_stats: [{
            question_id: 'id38',
            answered_count: 1,
            answers: [{
              student_names: ['Jim', 'Jack'],
              free_response: 'Hello',
              answer_id: 1
            }]
          }]
        }]
      }
    }
  }

  subject(:represented) do
    described_class.new(Hashie::Mash.new(page)).to_hash
  end

  it 'represents page stats' do
    expect(represented).to eq({
      'id' => '1',
      'title' => 'My page',
      'student_count' => 1,
      'correct_count' => 1,
      'incorrect_count' => 0,
      'chapter_section' => [1, 2],
      'exercises' => [{
        'content' => 'Cool content',
        'question_stats' => [{
          'question_id' => 'id42',
          'answered_count' => 1,
          'answers' => [{ 'student_names' => ['Jim', 'Jack'],
                          'free_response' => 'Hello',
                          'answer_id' => 1 }]
        }],

      }],
      'previous_attempt' => {
        'id' => '1',
        'title' => 'My page',
        'student_count' => 1,
        'correct_count' => 0,
        'incorrect_count' => 1,
        'chapter_section' => [1, 2],
        'exercises' => [{
          'content' => 'Cool content',
          'question_stats' => [{
            'question_id' => 'id38',
            'answered_count' => 1,
            'answers' => [{ 'student_names' => ['Jim', 'Jack'],
                            'free_response' => 'Hello',
                            'answer_id' => 1 }]
           }]

        }]
      }
    })
  end
end
