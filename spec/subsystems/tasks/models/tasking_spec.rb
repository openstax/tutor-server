require 'rails_helper'

RSpec.describe Tasks::Models::Tasking, type: :model do
  subject(:tasking) { FactoryGirl.create(:tasks_tasking) }

  it { is_expected.to belong_to(:task) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to belong_to(:period) }

  it { is_expected.to validate_presence_of(:task) }
  it { is_expected.to validate_presence_of(:role) }

  it { is_expected.to validate_uniqueness_of(:role).scoped_to(:tasks_task_id) }

  it "requires role to be unique for the task" do
    expect(tasking).to be_valid

    expect(FactoryGirl.build(:tasks_tasking, task: tasking.task,
                             role: tasking.role)).to_not be_valid
  end
end
