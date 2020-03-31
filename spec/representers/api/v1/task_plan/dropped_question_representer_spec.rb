require 'rails_helper'

RSpec.describe Api::V1::TaskPlan::DroppedQuestionRepresenter, type: :representer do
  let(:dropped_question) do
    instance_spy(Tasks::Models::DroppedQuestion).tap do |dbl|
      ## bug work-around, see:
      ##   https://github.com/rspec/rspec-rails/issues/1309#issuecomment-118971828
      allow(dbl).to receive(:as_json).and_return(dbl)
    end
  end

  let(:representation) do ## NOTE: This is lazily-evaluated on purpose!
    Api::V1::TaskPlan::DroppedQuestionRepresenter.new(dropped_question).as_json
  end

  context 'question_id' do
    it 'can be read' do
      expect(dropped_question).to receive(:question_id).and_return(12)
      expect(representation).to include('question_id' => '12')
    end

    it 'can be written' do
      described_class.new(dropped_question).from_json({ question_id: '42' }.to_json)
      expect(dropped_question).to have_received(:question_id=).with('42')
    end
  end

  context 'drop_method' do
    let(:drop_method) { [ :zeroed, :full_credit ].sample }

    it 'can be read' do
      expect(dropped_question).to receive(:drop_method).and_return(drop_method)
      expect(representation).to include('drop_method' => drop_method.to_s)
    end

    it 'can be written' do
      described_class.new(dropped_question).from_json({ drop_method: drop_method }.to_json)
      expect(dropped_question).to have_received(:drop_method=).with(drop_method.to_s)
    end
  end
end
