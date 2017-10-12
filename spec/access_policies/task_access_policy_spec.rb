require 'rails_helper'

RSpec.describe TaskAccessPolicy, type: :access_policy do
  let(:requestor)          { FactoryGirl.create(:user) }
  let(:task)               { FactoryGirl.create(:tasks_task) }

  subject(:action_allowed) { TaskAccessPolicy.action_allowed?(action, requestor, task) }

  context 'when the action is :read' do
    let(:action) { :read }

    context 'and the requestor is human' do
      # already true for User

      context 'and the requestor has taskings in the task' do
        before { allow(DoesTaskingExist).to receive(:[]) { true } }

        context "and the task's open date has passed" do
          before { allow(task).to receive(:past_open?) { true } }

          it { should eq true }
        end

        context "and the task's open date has not passed" do
          before { allow(task).to receive(:past_open?) { false } }

          it { should eq false }
        end
      end

      context 'and the requestor has no taskings in the task' do
        before { allow(DoesTaskingExist).to receive(:[]) { false } }

        context 'and the task has a course' do
          it { should eq false }
        end

        context 'and the task has no course' do
          before do
            @task_plan = task.task_plan
            task.update_attribute :task_plan, nil
          end

          after { task.update_attribute :task_plan, @task_plan }

          it { should eq false }
        end
      end

      context 'and the requestor is a course teacher' do
        before { allow(UserIsCourseTeacher).to receive(:[]) { true } }

        it { should eq true }
      end
    end

    context 'and the requestor is not human' do
      before { allow(requestor).to receive(:is_human?) { false } }

      it { should eq false }
    end
  end

  context 'when the action is :accept_or_reject_late_work' do
    let(:action) { :accept_or_reject_late_work }

    context 'and the requestor is human' do
      # already true for User

      context 'and the task_plan is withdrawn' do
        before do
          task.task_plan.destroy!
          allow(DoesTaskingExist).to receive(:[]) { true }
          allow(UserIsCourseTeacher).to receive(:[]) { true }
        end

        it { should eq false }
      end

      context 'and the task_plan is not withdrawn' do
        context 'and the requestor is a course teacher' do
          before { allow(UserIsCourseTeacher).to receive(:[]) { true } }

          it { should eq true }
        end

        context 'and the requestor is not a course teacher' do
          before { allow(DoesTaskingExist).to receive(:[]) { true } }

          it { should eq false }
        end
      end
    end

    context 'and the requestor is not human' do
      before { allow(requestor).to receive(:is_human?) { false } }

      it { should eq false }
    end
  end

  context 'when the action is :hide' do
    let(:action) { :hide }

    context 'and the requestor is human' do
      # already true for User

      context 'and the task_plan is withdrawn' do
        before { task.task_plan.destroy! }

        context 'and the requestor has taskings in the task' do
          before { allow(DoesTaskingExist).to receive(:[]) { true } }

          it { should eq true }
        end

        context 'and the requestor has no taskings in the task' do
          before { allow(UserIsCourseTeacher).to receive(:[]) { true } }

          it { should eq false }
        end
      end

      context 'and the task_plan is not withdrawn' do
        before do
          allow(DoesTaskingExist).to receive(:[]) { true }
          allow(UserIsCourseTeacher).to receive(:[]) { true }
        end

        it { should eq false }
      end
    end

    context 'and the requestor is not human' do
      before { allow(requestor).to receive(:is_human?) { false } }

      it { should eq false }
    end
  end

  [:create, :update, :destroy, :made_up].each do |disallowed_action|
    context "when the action is :#{disallowed_action}" do
      let(:action) { disallowed_action }

      it { should eq false }
    end
  end
end
