require 'rails_helper'

RSpec.describe Tasks::Models::TaskedPlaceholder, type: :model do
  subject(:tasked_placeholder) { FactoryBot.create(:tasks_tasked_placeholder) }

  it { is_expected.to validate_presence_of(:placeholder_type) }

  context 'placeholder types' do
    it "is created with 'unknown_type' placeholder type by default" do
      expect(subject.unknown_type?).to be_truthy
    end

    it "supports the 'exercise_type' placeholder type" do
      subject.exercise_type!
      expect(subject.exercise_type?).to be_truthy
    end
  end

  it 'returns the correct available_points' do
    tasked_placeholder.task_step.task.homework!

    # Full reload, including reloading our custom instance variables
    id = tasked_placeholder.id
    tasked_placeholder = described_class.find id
    expect(tasked_placeholder.available_points).to eq 1.0

    task_plan = tasked_placeholder.task_step.task.task_plan
    task_plan.type = 'homework'
    task_plan.settings = {
      exercises: [ { id: rand(10), points: [ 2.0 ] } ]
    }
    task_plan.save validate: false

    id = tasked_placeholder.id
    tasked_placeholder = described_class.find id
    expect(tasked_placeholder.available_points).to eq 2.0
  end
end
