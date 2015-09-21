require 'rails_helper'

RSpec.describe PropagateTaskPlanUpdates, type: :routine do
  let!(:course)          { Entity::Course.create! }
  let!(:period)          { CreatePeriod[course: course] }
  let!(:profile)            {
    profile = FactoryGirl.create :user_profile_profile
    AddUserAsPeriodStudent.call(user: profile.user, period: period)
    profile
  }

  let!(:old_title)       { 'Old Title' }
  let!(:old_description) { 'Old description' }

  let!(:task_plan)       { FactoryGirl.create(:tasks_task_plan, owner: course,
                                                                title: old_title,
                                                                description: old_description) }
  let!(:tasking_plan)    { FactoryGirl.create(:tasks_tasking_plan, target: profile,
                                                                   task_plan: task_plan) }

  let!(:new_title)       { 'New Title' }
  let!(:new_description) { 'New description' }

  context 'unpublished task_plan' do
    before(:each) do
      task_plan.title = 'New title'
      task_plan.description = 'New description'
      task_plan.save!
    end

    it 'does nothing' do
      expect(task_plan.tasks).to be_empty

      expect {
        PropagateTaskPlanUpdates.call(task_plan: task_plan)
      }.not_to change{ Tasks::Models::Task.count }

      expect(task_plan.tasks).to be_empty
    end
  end

  context 'published task_plan' do
    before(:each) do
      DistributeTasks.call(task_plan)
      task_plan.reload
      task_plan.title = new_title
      task_plan.description = new_description
      task_plan.save!
    end

    it 'propagates task_plan changes to all of its tasks' do
      expect(task_plan.tasks).not_to be_empty
      task_plan.tasks.each do |task|
        expect(task.title).to       eq old_title
        expect(task.description).to eq old_description
      end

      expect {
        PropagateTaskPlanUpdates.call(task_plan: task_plan)
      }.not_to change{ Tasks::Models::Task.count }

      expect(task_plan.tasks).not_to be_empty
      task_plan.tasks.each do |task|
        expect(task.title).to       eq new_title
        expect(task.description).to eq new_description
      end
    end
  end
end
