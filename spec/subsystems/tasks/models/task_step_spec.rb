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
end
