require 'rails_helper'

RSpec.describe HasOneExerciseStep do
  [:multiple_choice, :free_response].each do |step_class|
    subject(:step) { FactoryGirl.create "exercise_step_#{step_class}".to_sym }

    it { is_expected.to have_one(:exercise_step).dependent(:destroy) }

    it { is_expected.to validate_presence_of(:exercise_step) }

    it "causes #{step_class} to delegate methods to its exercise_step" do
      expect(step.completed_at).to be_nil
      expect(step.completed?).to eq false
      step.complete
      expect(step.completed_at).to eq step.exercise_step.completed_at
      expect(step.completed?).to eq true
    end
  end
end
