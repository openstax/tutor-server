require 'rails_helper'

RSpec.describe Tasks::Models::TaskStep, :type => :model do
  subject(:task_step) { FactoryGirl.create :tasks_task_step }

  it { is_expected.to belong_to(:task) }
  it { is_expected.to belong_to(:tasked) }

  it { is_expected.to validate_presence_of(:task) }
  it { is_expected.to validate_presence_of(:tasked) }
  it { is_expected.to validate_presence_of(:group_type) }

  it "requires tasked to be unique" do
    expect(task_step).to be_valid

    expect(FactoryGirl.build(:tasks_task_step,
                             tasked: task_step.tasked)).not_to be_valid
  end

  it "invalidates task's cache when updated" do
    task_step.tasked = FactoryGirl.build :tasks_tasked_exercise, task_step: task_step
    expect { task_step.save! }.to change{ task_step.task.cache_key }
  end

  it "converts its group type to a name" do
    name_by_type = {
      "default_group"         => "default",
      "core_group"            => "core",
      "spaced_practice_group" => "spaced practice",
      "personalized_group"    => "personalized"
    }

    Tasks::Models::TaskStep.group_types.keys.each do |group_type|
      allow(task_step).to receive(:group_type).and_return(group_type)
      expect(task_step.group_name).to eq(name_by_type[group_type])
    end
  end
end
