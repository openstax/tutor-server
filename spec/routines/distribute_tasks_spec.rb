require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine do

  let(:course)    { Entity::Course.create! }
  let(:period)    { CreatePeriod[course: course] }
  let(:user)      { FactoryGirl.create :user_profile }
  let(:task_plan) { FactoryGirl.create(:tasks_task_plan, owner: course) }
  let(:tasking_plan) { FactoryGirl.create(:tasks_tasking_plan, target: user,
                                                               task_plan: task_plan) }

  before do
    AddUserAsPeriodStudent.call(user: user.entity_user, period: period)
  end

  context 'no steps in any of the tasks' do
    it 'adds an error' do
      allow_any_instance_of(Tasks::Models::Task).to receive(:task_steps) { [] }

      error = DistributeTasks.call(task_plan).errors.last

      expect(error).not_to be_nil
      expect(error.code).to eq(:empty_tasks)
      expect(error.message).to eq(
        'Tasks could not be published because some tasks were empty'
      )
    end
  end

  context 'unpublished task_plan' do
    before do
      expect(DummyAssistant).to receive(:build_tasks).and_return([])
    end

    it "calls the build_tasks method on the task_plan's assistant" do
      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.tasks.size).to eq 2
    end

    it 'sets the published_at field' do
      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.reload.published_at).to be_within(1.second).of(Time.now)
    end
  end

  context 'published task_plan' do
    before do
      DistributeTasks.call(task_plan)
      new_user.entity_user.roles.each do |role|
        role.taskings.each{ |tasking| tasking.task.destroy }
      end
      task_plan.reload
      expect(DummyAssistant).to receive(:build_tasks).and_return([])
    end

    context 'before the open date' do
      before(:each) do
        opens_at = Time.now.tomorrow
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |tt| tt.update_attribute(:opens_at, opens_at) }
      end

      it 'rebuilds the tasks for the task_plan' do
        expect(task_plan.tasks.size).to eq 1
        old_task = task_plan.tasks.first

        result = DistributeTasks.call(task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 2
        expect(task_plan.tasks).not_to include old_task
      end

      it 'does not set the published_at field' do
        old_published_at = task_plan.published_at
        publish_time = Time.now
        result = DistributeTasks.call(task_plan, publish_time)
        expect(result.errors).to be_empty
        expect(task_plan.reload.published_at).to eq old_published_at
      end
    end

    context 'after the open date' do
      before(:each) do
        opens_at = Time.now.yesterday
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |tt| tt.update_attribute(:opens_at, opens_at) }
      end

      it 'does not rebuild existing tasks for the task_plan' do
        expect(task_plan.tasks.size).to eq 1
        old_task = task_plan.tasks.first

        result = DistributeTasks.call(task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 2
        expect(task_plan.tasks).to include old_task
      end

      it 'does not set the published_at field' do
        old_published_at = task_plan.published_at
        publish_time = Time.now
        result = DistributeTasks.call(task_plan, publish_time)
        expect(result.errors).to be_empty
        expect(task_plan.reload.published_at).to eq old_published_at
      end
    end
  end
end
