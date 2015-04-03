require 'rails_helper'

RSpec.describe ActsAsTasked do
  [:tasks_tasked_reading, :tasks_tasked_exercise].each do |tasked_class|
    subject(:tasked) { FactoryGirl.create tasked_class }

    it { is_expected.to have_one(:task_step) }

    it "causes #{tasked_class} to delegate methods to its task_step" do
      expect(tasked.completed_at).to be_nil
      expect(tasked.completed?).to eq false

      tasked.complete

      expect(tasked.completed_at).to eq tasked.task_step.completed_at
      expect(tasked.completed?).to eq true
    end
  end
end
