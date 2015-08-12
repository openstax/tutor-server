require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine do

  let!(:course)    { Entity::Course.create! }
  let!(:period)    { CreatePeriod[course: course] }
  let!(:user)      {
    profile = FactoryGirl.create :user_profile
    AddUserAsPeriodStudent.call(user: profile.entity_user, period: period)
    profile
  }
  let!(:task_plan) {
    task_plan = FactoryGirl.build(:tasks_task_plan, owner: course)
    task_plan.tasking_plans.first.target = user
    task_plan.save!
    task_plan
  }

  context 'unpublished task_plan' do
    it "creates tasks for the task_plan" do
      expect(task_plan.tasks).to be_empty
      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.tasks.size).to eq 1
    end

    it "sets the published_at field" do
      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
    end
  end

  context 'published task_plan' do
    before(:each) do
      DistributeTasks.call(task_plan)
      task_plan.reload
    end

    it "rebuilds the tasks for the task_plan" do
      expect(task_plan.tasks.size).to eq 1
      old_task = task_plan.tasks.first

      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.reload.tasks.size).to eq 1
      expect(task_plan.tasks.first).not_to eq old_task
    end

    it "sets the published_at field" do
      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
    end
  end
end
