require 'rails_helper'

RSpec.describe Api::V1::Tasks::Stats::ExerciseRepresenter, type: :representer do
  let(:exercise_stats) { { content: '{ "some": "json" }',
                           content_hash: { 'some' => 'json' },
                           question_stats: [{
                             answered_count: 1,
                             answers: [{
                               students: [{ id: 1, name: 'Jim' },{ id: 2, name: 'Jack' }],
                               free_response: 'Hello',
                               answer_id: 1
                             }],
                             answer_stats: [{
                               answer_id: 'abc',
                               selected_count: 7
                             }]
                           }] } }


  subject(:represented) do
    described_class.new(Hashie::Mash.new(exercise_stats)).to_hash
  end

  it 'represents exercise stats' do
    expect(represented).to eq({
      'content' => exercise_stats[:content_hash],
      'question_stats' => [{
        'answered_count' => 1,
        'answers' => [{ 'students' => [{ 'id' => 1, 'name' => 'Jim' }, { 'id' => 2, 'name' => 'Jack' }],
                        'free_response' => 'Hello',
                        'answer_id' => 1 }],
        'answer_stats' => [{ 'answer_id' => 'abc', 'selected_count' => 7 }]
      }]

    })
  end
end
