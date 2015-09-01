require 'rails_helper'

RSpec.describe ReassignPublishedPeriodTaskPlans, type: :routine do

  let!(:course)    { Entity::Course.create! }
  let!(:period)    { CreatePeriod[course: course] }
  let!(:user)      {
    profile = FactoryGirl.create :user_profile
    AddUserAsPeriodStudent.call(user: profile.entity_user, period: period)
    profile
  }
  let!(:task_plan_1) {
    task_plan = FactoryGirl.build(:tasks_task_plan, owner: course)
    task_plan.tasking_plans.first.target = period.to_model
    task_plan.save!
    task_plan
  }
  let!(:task_plan_2) {
    task_plan = FactoryGirl.build(:tasks_task_plan, owner: course)
    task_plan.tasking_plans.first.target = period.to_model
    task_plan.save!
    task_plan
  }
  let!(:new_user)  { FactoryGirl.create :user_profile }

  before(:each) {
    DistributeTasks.call(task_plan_1)
    AddUserAsPeriodStudent.call(user: new_user.entity_user, period: period,
                                assign_published_task_plans: false)
  }

  context 'unpublished task_plan' do
    it 'does not do anything' do
      result = nil
      expect{
        result = ReassignPublishedPeriodTaskPlans.call(period: period)
      }.not_to change{task_plan_2.published_at}
      expect(result.errors).to be_empty
      expect(task_plan_2.tasks.size).to eq 0
    end
  end

  context 'published task_plan' do
    it 'assigns tasks to the new student but does not modify existing tasks' do
      expect(task_plan_1.tasks.size).to eq 1
      old_task = task_plan_1.tasks.first
      result = nil
      expect{
        result = ReassignPublishedPeriodTaskPlans.call(period: period)
      }.not_to change{task_plan_1.published_at}
      expect(result.errors).to be_empty
      expect(task_plan_1.tasks.size).to eq 2
      expect(task_plan_1.tasks).to include old_task
      new_task = task_plan_1.tasks.reject{ |tt| tt == old_task }.first
      expect(new_task.taskings.first.role.user).to eq new_user.entity_user
    end
  end
end
