require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine do
  context 'unpublished task_plan' do
    let!(:user)      { FactoryGirl.create :user_profile }
    let!(:task_plan) { FactoryGirl.create(:tasks_tasking_plan, target: user).task_plan }

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
    let!(:user)      { FactoryGirl.create :user_profile }
    let!(:task_plan) {
      tp = FactoryGirl.create(:tasks_tasking_plan, target: user).task_plan
      DistributeTasks.call(tp)
      tp.reload
    }

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
end
