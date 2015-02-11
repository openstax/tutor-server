require 'rails_helper'

RSpec.describe ActsAsSubtasked do
  [:multiple_choice, :free_response].each do |subtasked_class|
    subject(:subtasked) { FactoryGirl.create subtasked_class }

    it { is_expected.to have_one(:exercise_substep).dependent(:destroy) }

    it { is_expected.to validate_presence_of(:exercise_substep) }

    it "causes #{subtasked_class} to delegate to its exercise_substep" do
      expect(subtasked.completed_at).to be_nil
      expect(subtasked.completed?).to eq false

      subtasked.complete

      expect(subtasked.completed_at).to(
        eq subtasked.exercise_substep.completed_at
      )
      expect(subtasked.completed?).to eq true
    end
  end
end
