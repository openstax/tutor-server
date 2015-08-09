require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine do

  let!(:course)    { Entity::Course.create! }
  let!(:period)    { CreatePeriod[course: course] }
  let!(:user)      {
    profile = FactoryGirl.create :user_profile
    AddUserAsPeriodStudent.call(user: profile.entity_user, period: period)
    profile
  }
  let!(:task_plan) { FactoryGirl.create(:tasks_task_plan, owner: course) }
  let!(:tasking_plan) { FactoryGirl.create(:tasks_tasking_plan, target: user, task_plan: task_plan) }

  context 'unpublished task_plan' do
    it "calls the build_tasks method on the task_plan's assistant" do
      expect(DummyAssistant).to receive(:build_tasks).and_return([])

      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
    end

    it "sets the published_at field" do
      DistributeTasks.call(task_plan)
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
    end
  end

  context 'published task_plan' do
    before(:each) do
      DistributeTasks.call(task_plan)
      task_plan.reload
    end

    it "calls the build_tasks method on the task_plan's assistant" do
      expect_any_instance_of(DummyAssistant).to receive(:build_tasks).and_return([])

      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
    end

    it "sets the published_at field" do
      DistributeTasks.call(task_plan)
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
    end
  end
end
