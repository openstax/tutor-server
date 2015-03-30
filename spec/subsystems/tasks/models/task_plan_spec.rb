require 'rails_helper'

RSpec.describe Tasks::Models::TaskPlan, :type => :model do
  it { is_expected.to belong_to(:assistant) }
  it { is_expected.to belong_to(:owner) }

  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }
  it { is_expected.to have_many(:tasks).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:assistant) }
  it { is_expected.to validate_presence_of(:opens_at) }

  it "requires non-nil due_at to be after opens_at" do
    task_plan = FactoryGirl.build(:tasks_task_plan, due_at: nil)
    expect(task_plan).to be_valid

    task_plan = FactoryGirl.build(:tasks_task_plan, opens_at: Time.now, due_at: Time.now - 1.week)
    expect(task_plan).to_not be_valid
  end
end
