require 'rails_helper'

RSpec.describe ActsAsTasked do
  [:tasks_tasked_reading, :tasks_tasked_exercise].each do |tasked_class|
    subject(:tasked) { FactoryGirl.create tasked_class }

    it { is_expected.to have_one(:task_step) }

    it "causes #{tasked_class} to delegate methods to its task_step" do
      expect(tasked.first_completed_at).to be_nil
      expect(tasked).to_not be_completed

      tasked.complete

      expect(tasked.first_completed_at).to eq tasked.task_step.first_completed_at
      expect(tasked).to be_completed
    end
  end
end
