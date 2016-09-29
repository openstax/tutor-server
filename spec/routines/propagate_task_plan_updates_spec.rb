require 'rails_helper'

RSpec.describe PropagateTaskPlanUpdates, type: :routine do
  let(:course)          { FactoryGirl.create :course_profile_course }
  let(:period)          { FactoryGirl.create :course_membership_period, course: course }
  let!(:user)           do
    FactoryGirl.create(:user).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end

  let(:old_title)       { 'Old Title' }
  let(:old_description) { 'Old description' }

  let(:task_plan)       do
    FactoryGirl.create(:tasks_task_plan, owner: course,
                                         title: old_title,
                                         description: old_description)
  end

  let!(:tasking_plan)    do
    task_plan.tasking_plans.first.tap do |tasking_plan|
      tasking_plan.update_attribute(:target, period.to_model)
    end
  end

  let(:old_opens_at)    { tasking_plan.opens_at }
  let(:old_due_at)      { tasking_plan.due_at }

  let(:new_title)       { 'New Title' }
  let(:new_description) { 'New description' }

  let(:time_zone)       { tasking_plan.time_zone.to_tz }
  let(:new_opens_at)    { time_zone.now + 10.seconds }
  let(:new_due_at)      { time_zone.now + 1.week + 10.seconds }

  context 'unpublished task_plan' do
    before(:each) do
      task_plan.title = 'New title'
      task_plan.description = 'New description'
      task_plan.save!
    end

    it 'does nothing' do
      expect(task_plan.tasks).to be_empty

      expect do
        PropagateTaskPlanUpdates.call(task_plan: task_plan)
      end.not_to change{ Tasks::Models::Task.count }

      expect(task_plan.tasks).to be_empty
    end
  end

  context 'published task_plan' do
    before(:each) do
      DistributeTasks.call(task_plan: task_plan)

      task_plan.reload
      task_plan.title = new_title
      task_plan.description = new_description
      tasking_plan = task_plan.tasking_plans.first
      tasking_plan.opens_at = new_opens_at
      tasking_plan.due_at = new_due_at
      tasking_plan.save!
      task_plan.save!
    end

    context 'homework' do
      it 'propagates task_plan changes (except opens_at) to all of its tasks' do
        task_plan.type = 'homework'
        task_plan.is_feedback_immediate = false
        task_plan.save!(validate: false)

        expect(task_plan.tasks).not_to be_empty
        task_plan.tasks.each do |task|
          expect(task.title).to       eq old_title
          expect(task.description).to eq old_description
          expect(task.opens_at).to    be_within(1e-6).of(old_opens_at)
          expect(task.due_at).to      be_within(1e-6).of(old_due_at)
        end
        allow(task_plan.assistant).to(
          receive(:code_class).and_return(Tasks::Assistants::HomeworkAssistant)
        )

        expect do
          PropagateTaskPlanUpdates.call(task_plan: task_plan)
        end.not_to change{ Tasks::Models::Task.count }

        expect(task_plan.tasks).not_to be_empty
        task_plan.tasks.each do |task|
          expect(task.title).to       eq new_title
          expect(task.description).to eq new_description
          expect(task.opens_at).to    be_within(1e-6).of(old_opens_at)
          expect(task.due_at).to      be_within(1e-6).of(new_due_at)
          expect(task.feedback_at).to eq task.due_at
        end
      end

      it 'sets feedback_at to nil when feedback is immediate' do
        allow(task_plan.assistant).to(
          receive(:code_class).and_return(Tasks::Assistants::HomeworkAssistant)
        )
        task_plan.update_attributes(type: 'homework', is_feedback_immediate: true)
        PropagateTaskPlanUpdates.call(task_plan: task_plan)
        task_plan.tasks.each do |task|
          expect(task.feedback_at).to be_nil
        end
      end

    end

    context 'reading' do
      it 'propagates task_plan changes (except opens_at) to all of its tasks' do
        task_plan.update_attribute(:type, 'reading')
        expect(task_plan.tasks).not_to be_empty
        task_plan.tasks.each do |task|
          expect(task.title).to       eq old_title
          expect(task.description).to eq old_description
          expect(task.opens_at).to    be_within(1e-6).of(old_opens_at)
          expect(task.due_at).to      be_within(1e-6).of(old_due_at)
        end

        expect do
          PropagateTaskPlanUpdates.call(task_plan: task_plan)
        end.not_to change{ Tasks::Models::Task.count }

        expect(task_plan.tasks).not_to be_empty
        task_plan.tasks.each do |task|
          expect(task.title).to       eq new_title
          expect(task.description).to eq new_description
          expect(task.opens_at).to    be_within(1e-6).of(old_opens_at)
          expect(task.due_at).to      be_within(1e-6).of(new_due_at)
          expect(task.feedback_available?).to be_truthy
        end
      end
    end
  end
end
