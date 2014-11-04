require 'rails_helper'

RSpec.describe TaskPlan, :type => :model do
  it { is_expected.to belong_to(:owner) }

  it { is_expected.to have_many(:tasking_plans).dependent(:destroy) }
  it { is_expected.to have_many(:tasks).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:assistant) }
  it { is_expected.to validate_presence_of(:configuration) }
  it { is_expected.to validate_presence_of(:assign_after) }

  it "requires non-nil assigned_at to be after assign_after" do
    task_plan = FactoryGirl.build(:task_plan, assigned_at: nil)
    expect(task_plan).to be_valid

    task_plan = FactoryGirl.build(:task_plan, assigned_at: Time.now - 1.week)
    expect(task_plan).to_not be_valid
  end
end
