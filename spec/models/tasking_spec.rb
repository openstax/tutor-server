require 'rails_helper'

RSpec.describe Tasking, :type => :model do
  it { is_expected.to belong_to(:assignee) }
  it { is_expected.to belong_to(:task).counter_cache(true) }
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_presence_of(:assignee) }
  it { is_expected.to validate_presence_of(:task) }
  it { is_expected.to validate_presence_of(:user) }

  it "requires assignee and user to be unique for the task" do
    tasking = FactoryGirl.create(:tasking)
    expect(tasking).to be_valid

    expect(FactoryGirl.build(:tasking, task: tasking.task,
                             assignee: tasking.assignee)).to_not be_valid

    expect(FactoryGirl.build(:tasking, task: tasking.task,
                             user: tasking.user)).to_not be_valid
  end

  it "requires user to match assignee" do
    expect(FactoryGirl.build(:tasking)).to be_valid

    expect(FactoryGirl.build(:tasking,
                             user: FactoryGirl.create(:user))).to_not be_valid
  end
end

