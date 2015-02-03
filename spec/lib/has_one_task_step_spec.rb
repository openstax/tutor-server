require 'rails_helper'

RSpec.describe HasOneTaskStep do
  [:reading, :exercise, :interactive].each do |step_class|
    subject(:step) { FactoryGirl.create "#{step_class}_step".to_sym }

    it { is_expected.to have_one(:task_step).dependent(:destroy) }

    it { is_expected.to validate_presence_of(:task_step) }

    it "causes #{step_class} to delegate methods to its task_step" do
      expect(step.url).to eq step.task_step.url
      expect(step.content).to eq step.task_step.content
      expect(step.completed_at).to be_nil
      expect(step.completed?).to eq false
      step.complete
      expect(step.completed_at).to eq step.task_step.completed_at
      expect(step.completed?).to eq true
    end
  end
end
