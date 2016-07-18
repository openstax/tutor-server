require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine do

  let(:course)    { FactoryGirl.create :entity_course }
  let(:period)    { CreatePeriod[course: course] }
  let!(:user)     {
    user = FactoryGirl.create(:user)
    AddUserAsPeriodStudent.call(user: user, period: period)
    user
  }
  let!(:new_user) {
    user = FactoryGirl.create(:user)
    AddUserAsPeriodStudent.call(user: user, period: period)
    user
  }
  let(:task_plan) {
    task_plan = FactoryGirl.build(:tasks_task_plan, owner: course)
    task_plan.tasking_plans.first.target = period.to_model
    task_plan.save!
    task_plan
  }

  context 'unpublished task_plan' do
    it 'creates tasks for the task_plan' do
      expect(task_plan.tasks).to be_empty
      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.tasks.size).to eq 2
    end

    it 'sets the published_at fields' do
      result = DistributeTasks.call(task_plan)
      expect(result.errors).to be_empty
      expect(task_plan.reload.first_published_at).to be_within(1.second).of(Time.current)
      expect(task_plan.reload.last_published_at).to be_within(1.second).of(Time.current)
    end

    it 'fails to publish the task_plan if one or more non-stepless tasks would be empty' do
      original_build_tasks = DummyAssistant.instance_method(:build_tasks)
      allow_any_instance_of(DummyAssistant).to receive(:build_tasks) do |receiver|
        tasks = original_build_tasks.bind(receiver).call
        tasks.each{ |task| task.task_type = :reading }
      end

      expect(task_plan.tasks).to be_empty
      result = DistributeTasks.call(task_plan)
      expect(result.errors.first.code).to eq :empty_tasks
      expect(task_plan.tasks).to be_empty
    end
  end

  context 'published task_plan' do
    before(:each) do
      DistributeTasks.call(task_plan)
      new_user.to_model.roles.each do |role|
        role.taskings.each{ |tasking| tasking.task.really_destroy! }
      end
      task_plan.reload
    end

    context 'before the open date' do
      before(:each) do
        opens_at = Time.current.tomorrow
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |task| task.update_attribute(:opens_at, opens_at) }
      end

      it 'rebuilds the tasks for the task_plan' do
        expect(task_plan.tasks.size).to eq 1
        old_task = task_plan.tasks.first

        result = DistributeTasks.call(task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 2
        expect(task_plan.tasks).not_to include old_task
      end

      it 'does not set the first_published_at field' do
        old_published_at = task_plan.first_published_at
        publish_time = Time.current
        result = DistributeTasks.call(task_plan, publish_time)
        expect(result.errors).to be_empty
        expect(task_plan.reload.first_published_at).to eq old_published_at
        expect(task_plan.last_published_at).to be_within(1).of(publish_time)
      end
    end

    context 'after the open date' do
      before(:each) do
        opens_at = Time.current.yesterday
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |task| task.update_attribute(:opens_at, opens_at) }
      end

      it 'does not rebuild existing tasks for the task_plan' do
        expect(task_plan.tasks.size).to eq 1
        old_task = task_plan.tasks.first

        result = DistributeTasks.call(task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 2
        expect(task_plan.tasks).to include old_task
      end

      it 'does not set the first_published_at field' do
        old_published_at = task_plan.first_published_at
        publish_time = Time.current
        result = DistributeTasks.call(task_plan, publish_time)
        expect(result.errors).to be_empty
        expect(task_plan.reload.first_published_at).to eq old_published_at
        expect(task_plan.last_published_at).to be_within(1).of(publish_time)
      end
    end
  end
end
