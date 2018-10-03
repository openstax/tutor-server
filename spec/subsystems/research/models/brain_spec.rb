require 'rails_helper'

RSpec.describe Research::Models::Brain, type: :model do

    let(:brain) { FactoryBot.create :research_study_brain }

    it 'evals code' do
      brain.code = 'task_step.foo'
      task_step = OpenStruct.new(foo: '1234')
      expect(brain.evaluate(binding())).to eq '1234'
    end

    it 'validates hooks' do
      brain.update_attributes hook: 'test'
      expect(brain.errors[:hook].first).to include 'is not valid for domain'
    end
end
