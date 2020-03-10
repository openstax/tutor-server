require 'rails_helper'

RSpec.describe Api::V1::Tasks::Stats::AnswerRepresenter, type: :representer do
  let(:answer) { { students: [{ id: 1, name: 'Jim' },{ id: 2, name: 'Jack' }],
                   free_response: 'Hello',
                   answer_id: 1 } }

  subject(:represented) do
    described_class.new(Hashie::Mash.new(answer)).to_hash
  end

  it 'represents answers' do
    expect(represented).to eq({
    'students' => [{ 'id' => 1, 'name' => 'Jim' }, { 'id' => 2, 'name' => 'Jack' }],
      'free_response' => 'Hello',
      'answer_id' => 1
    })
  end
end
