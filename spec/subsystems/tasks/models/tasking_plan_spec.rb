require 'rails_helper'

RSpec.describe Tasks::Models::TaskingPlan, :type => :model do
  it { is_expected.to belong_to(:target) }
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to validate_presence_of(:target) }
  it { is_expected.to validate_presence_of(:task_plan) }

  it "requires target to be unique for the task_plan" do
    tasking_plan = FactoryGirl.create(:tasking_plan)
    expect(tasking_plan).to be_valid

    expect(FactoryGirl.build(:tasking_plan,
                             task_plan: tasking_plan.task_plan,
                             target: tasking_plan.target)).to_not be_valid
  end
end
