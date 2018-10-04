require 'rails_helper'

RSpec.describe Research::Models::Brain, type: :model do

    let(:brain) { FactoryBot.create :research_study_brain }

    it 'validates hooks' do
      brain.update_attributes hook: 'test'
      expect(brain.errors[:hook].first).to include 'is not valid for domain'
    end

    it 'evals code' do
      brain.code = 'task_step.foo = "updated!"'
      task_step = OpenStruct.new(foo: '1234')
      expect(brain.evaluate(binding())).to be_nil
      expect(task_step.foo).to eq 'updated!'
    end

    it 'catches invalid code' do
      brain.code = 'bang()'
      task_step = OpenStruct.new(foo: '1234')
      err = brain.evaluate(binding())
      expect(err).to be_a(NoMethodError)
      expect(err.to_s).to include "undefined method `bang'"
    end

end
