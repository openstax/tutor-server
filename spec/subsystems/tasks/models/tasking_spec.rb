require 'rails_helper'

RSpec.describe Tasking, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"

  # Old tests from app/models/tasking.rb
  
  # it { is_expected.to belong_to(:taskee) }
  # it { is_expected.to belong_to(:task).counter_cache(true) }
  # it { is_expected.to belong_to(:user) }

  # it { is_expected.to validate_presence_of(:taskee) }
  # it { is_expected.to validate_presence_of(:task) }
  # it { is_expected.to validate_presence_of(:user) }

  # it "requires taskee and user to be unique for the task" do
  #   tasking = FactoryGirl.create(:tasking)
  #   expect(tasking).to be_valid

  #   expect(FactoryGirl.build(:tasking, task: tasking.task,
  #                            taskee: tasking.taskee)).to_not be_valid

  #   expect(FactoryGirl.build(:tasking, task: tasking.task,
  #                            user: tasking.user)).to_not be_valid
  # end

  # it "requires user to match taskee" do
  #   expect(FactoryGirl.build(:tasking)).to be_valid

  #   expect(FactoryGirl.build(:tasking,
  #                            user: FactoryGirl.create(:user))).to_not be_valid
  # end
end

