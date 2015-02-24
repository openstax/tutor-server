require 'rails_helper'

RSpec.describe Task, :type => :model do
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to have_many(:task_steps).dependent(:destroy) }
  it { is_expected.to have_many(:taskings).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:task_plan) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:opens_at) }

  it "requires non-nil due_at to be after opens_at" do
    task = FactoryGirl.build(:task, due_at: nil)
    expect(task).to be_valid

    task = FactoryGirl.build(:task, due_at: Time.now - 1.week)
    expect(task).to_not be_valid
  end

  it "reports is_shared correctly" do
    at1 = FactoryGirl.create(:tasking)
    at1.reload
    expect(at1.task.is_shared).to be_falsy

    at2 = FactoryGirl.create(:tasking, task: at1.task)
    at1.reload
    expect(at1.task.is_shared).to be_truthy
  end

  it 'reports any_tasks? for a taskee' do
    user = FactoryGirl.create(:user)
    tasking = FactoryGirl.build(:tasking, taskee: user)
    task = FactoryGirl.create(:task, taskings: [tasking])

    expect(task).to be_any_tasks(user)

    task.taskings.clear
    expect(task).not_to be_any_tasks(user)
  end
end
