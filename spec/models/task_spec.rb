require 'rails_helper'

RSpec.describe Task, :type => :model do
  it { is_expected.to have_many(:assigned_tasks).dependent(:destroy) }
  it { is_expected.to belong_to(:details).dependent(:destroy) }
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to validate_presence_of(:details) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:opens_at) }

  it "is expected to require non-nil due_at to be after opens_at" do
    task = FactoryGirl.build(:task, due_at: nil)
    expect(task).to be_valid

    task = FactoryGirl.build(:task, due_at: Time.now - 1.week)
    expect(task).to_not be_valid
  end

  it "is expected to report is_shared correctly" do
    at1 = FactoryGirl.create(:assigned_task)
    at1.reload
    expect(at1.task.is_shared).to be_falsy

    at2 = FactoryGirl.create(:assigned_task, task: at1.task)
    at1.reload
    expect(at1.task.is_shared).to be_truthy
  end
end

