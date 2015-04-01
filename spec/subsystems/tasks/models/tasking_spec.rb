require 'rails_helper'

RSpec.describe Tasks::Models::Tasking, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"

  it { is_expected.to belong_to(:role) }
  it { is_expected.to belong_to(:task) }

  it "requires role to be unique for the task" do
    tasking = FactoryGirl.create(:tasks_tasking)
    expect(tasking).to be_valid

    expect(FactoryGirl.build(:tasks_tasking, task: tasking.task,
                             role: tasking.role)).to_not be_valid
  end
end

