require 'rails_helper'

RSpec.describe Tasks::Models::Task, :type => :model do
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to have_many(:task_steps).dependent(:destroy) }
  it { is_expected.to have_many(:taskings).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:opens_at) }

  it "requires non-nil due_at to be after opens_at" do
    task = FactoryGirl.build(:tasks_task, due_at: nil)
    expect(task).to be_valid

    task = FactoryGirl.build(:tasks_task, due_at: Time.now - 1.week)
    expect(task).to_not be_valid
  end

  it "reports is_shared correctly" do
    task1 = FactoryGirl.create(:tasks_task)
    FactoryGirl.create(:tasks_tasking, task: task1.entity_task)
    expect(task1.is_shared).to be_falsy

    FactoryGirl.create(:tasks_tasking, task: task1.entity_task)
    expect(task1.is_shared).to be_truthy
  end

end
