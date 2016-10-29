require 'rails_helper'

RSpec.describe ReassignPublishedPeriodTaskPlans, type: :routine do

  let(:course)    { FactoryGirl.create :course_profile_course }
  let(:period)    { FactoryGirl.create :course_membership_period, course: course }
  let!(:user)      do
    FactoryGirl.create(:user).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let!(:new_user)    do
    FactoryGirl.create(:user).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let!(:task_plan_1) do
    FactoryGirl.build(:tasks_task_plan, owner: course).tap do |task_plan|
      task_plan.tasking_plans.first.target = period.to_model
      task_plan.save!
    end
  end
  let!(:task_plan_2) do
    FactoryGirl.build(:tasks_task_plan, owner: course).tap do |task_plan|
      task_plan.tasking_plans.first.target = period.to_model
      task_plan.save!
    end
  end

  before(:each) do
    # Publish task_plan_1
    DistributeTasks.call(task_plan_1)

    # We are pretending new_user is new to the period, so hard-delete their tasks
    new_user.to_model.roles.each do |role|
      role.taskings.each{ |tasking| tasking.task.really_destroy! }
    end

    task_plan_1.tasks.reset
  end

  context 'unpublished task_plan' do
    it 'does not do anything' do
      result = nil
      expect do
        result = ReassignPublishedPeriodTaskPlans.call(period: period.to_model)
      end.not_to change{task_plan_2.last_published_at}
      expect(result.errors).to be_empty
      expect(task_plan_2.tasks.size).to eq 0
    end
  end

  context 'published task_plan' do
    it 'assigns tasks to the new student but does not modify existing tasks' do
      expect(task_plan_1.tasks.size).to eq 1
      old_task = task_plan_1.tasks.first
      result = nil
      expect do
        result = ReassignPublishedPeriodTaskPlans.call(period: period.to_model)
      end.not_to change{task_plan_1.last_published_at}
      expect(result.errors).to be_empty
      expect(task_plan_1.tasks.size).to eq 2
      expect(task_plan_1.tasks).to include old_task
      new_task = task_plan_1.tasks.reject{ |task| task == old_task }.first
      expect(new_task.taskings.first.role.profile).to eq new_user.to_model
    end
  end
end
