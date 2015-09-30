require 'rails_helper'

RSpec.describe TaskedAccessPolicy, type: :access_policy do
  let(:requestor) {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let(:tasked)    { FactoryGirl.create(:tasks_tasked_exercise) }

  subject(:action_allowed) do
    TaskedAccessPolicy.action_allowed?(action, requestor, tasked)
  end

  [:read, :update, :mark_completed].each do |allowed_action|
    context "when the action is :#{allowed_action}" do
      let(:action) { allowed_action }

      context 'and the requestor is human' do
        before { allow(requestor).to receive(:is_human?) { true } }

        context 'and the tasked is part of a task for the requestor' do
          before { allow(DoesTaskingExist).to receive(:[]) { true } }

          context "and the task's open date has passed" do
            before { allow(tasked.task_step.task).to receive(:past_open?) { true } }

            it { should be true }
          end

          context "and the task's open date has not passed" do
            before { allow(tasked.task_step.task).to receive(:past_open?) { false } }

            it { should be false }
          end
        end

        context 'and the tasked is not part of a task for the requestor' do
          before { allow(DoesTaskingExist).to receive(:[]) { false } }

          it { should be false }
        end

        context 'and the requestor is a course teacher' do
          before { allow(DoesTaskingExist).to receive(:[]) { false }
                   allow(UserIsCourseTeacher).to receive(:[]) { true } }

          it { should be action == :read }
        end
      end

      context 'and the requestor is not human' do
        before { allow(requestor).to receive(:is_human?) { false } }

        it { should be false }
      end
    end
  end

  context 'when the action is unknown' do
    let(:action) { :unknown_fooey }

    it { should be false }
  end

  context 'when the tasking is in the tasks subsystem' do
    it 'allows access for the taskee' do
      role = Role::CreateUserRole[requestor]
      Tasks::CreateTasking.call(task: tasked.task_step.task, role: role)

      [:read, :update, :mark_completed].each do |allowed_action|
        expect(TaskedAccessPolicy.action_allowed?(allowed_action, requestor, tasked)).to be_truthy
      end
    end
  end
end
