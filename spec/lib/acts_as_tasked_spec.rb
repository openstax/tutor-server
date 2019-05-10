require 'rails_helper'

RSpec.describe ActsAsTasked, type: :model do
  context 'tasked_reading' do
    subject(:tasked) { FactoryBot.create :tasks_tasked_reading }

    it { is_expected.to have_one(:task_step) }

    it "causes the tasked_reading to delegate methods to its task_step" do
      expect(tasked.first_completed_at).to be_nil
      expect(tasked).not_to be_completed

      tasked.complete!

      expect(tasked.first_completed_at).to eq tasked.task_step.first_completed_at
      expect(tasked).to be_completed
    end
  end

  context 'tasked_exercise' do
    subject(:tasked) { FactoryBot.create :tasks_tasked_exercise }

    it { is_expected.to have_one(:task_step) }

    it "causes the tasked_exercise to delegate methods to its task_step" do
      expect(tasked.first_completed_at).to be_nil
      expect(tasked).not_to be_completed

      tasked.complete! # Fails due to no answer

      expect(tasked.first_completed_at).to be_nil
      expect(tasked).not_to be_completed

      tasked.free_response = 'Something'
      tasked.answer_id = tasked.correct_answer_id
      tasked.complete!

      expect(tasked.first_completed_at).to eq tasked.task_step.first_completed_at
      expect(tasked).to be_completed
    end
  end
end
