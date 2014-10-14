require 'rails_helper'

RSpec.describe AssignedTask, :type => :model do
  it { is_expected.to belong_to(:assignee) }
  it { is_expected.to belong_to(:task).counter_cache(true) }
  it { is_expected.to belong_to(:user) }

  it "is valid when user matches assignee" do
    expect(FactoryGirl.build(:assigned_task)).to be_valid
  end

  it "is invalid when user doesn't match assignee" do
    expect(FactoryGirl.build(:assigned_task, user: FactoryGirl.create(:user))).to_not be_valid
  end
end

