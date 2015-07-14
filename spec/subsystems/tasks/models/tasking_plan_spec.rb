require 'rails_helper'

RSpec.describe Tasks::Models::TaskingPlan, type: :model do
  subject(:tasking_plan) { FactoryGirl.create :tasks_tasking_plan }

  let!(:task_plan)       { tasking_plan.task_plan }
  let!(:target)          { tasking_plan.target }
  let!(:course)          { task_plan.owner }

  it { is_expected.to belong_to(:target) }
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to validate_presence_of(:target) }
  it { is_expected.to validate_presence_of(:task_plan) }

  it { is_expected.to validate_presence_of(:opens_at) }
  it { is_expected.to validate_presence_of(:due_at) }

  it "requires due_at to be after opens_at" do
    task = FactoryGirl.build(:tasks_task, opens_at: Time.now, due_at: Time.now - 1.hour)
    expect(task).to_not be_valid
  end

  it "requires target to be unique for the task_plan" do
    expect(tasking_plan).to be_valid

    expect(FactoryGirl.build(:tasks_tasking_plan,
                             task_plan: task_plan,
                             target: target)).to_not be_valid
  end

  it "does not allow owner to assign to a period in another course" do
    period_1 = FactoryGirl.create(:course_membership_period, course: course)
    period_2 = FactoryGirl.create(:course_membership_period)

    expect(tasking_plan).to be_valid
    tasking_plan.target = period_1
    expect(tasking_plan).to be_valid
    tasking_plan.target = period_2
    expect(tasking_plan).not_to be_valid
  end
end
