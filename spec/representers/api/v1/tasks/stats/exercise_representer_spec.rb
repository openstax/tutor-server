require 'rails_helper'

RSpec.describe Api::V1::Tasks::Stats::ExerciseRepresenter, :type => :representer do
  let(:exercise_stats) { { content: 'Cool content',
                           answered_count: 1,
                           answers: [{ student_names: ['Jim', 'Jack'],
                                       free_response: 'Hello',
                                       answer_id: 1 }] } }

  subject(:represented) do
    described_class.new(Hashie::Mash.new(exercise_stats)).to_hash
  end

  it 'represents exercise stats' do
    expect(represented).to eq({
      'content' => 'Cool content',
      'answered_count' => 1,
      'answers' => [{ 'student_names' => ['Jim', 'Jack'],
                      'free_response' => 'Hello',
                      'answer_id' => 1 }]
    })
  end
end
