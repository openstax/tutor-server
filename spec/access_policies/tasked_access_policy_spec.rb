require 'rails_helper'

RSpec.describe TaskedAccessPolicy, :type => :access_policy do
  let(:requestor) { FactoryGirl.create(:user_profile) }
  let(:tasked) { FactoryGirl.create(:tasks_tasked_exercise) }

  subject(:action_allowed) do
    TaskedAccessPolicy.action_allowed?(action, requestor, tasked)
  end

  [:read, :create, :update, :destroy, :mark_completed].each do |allowed_action|
    context "when the action is :#{allowed_action}" do
      let(:action) { allowed_action }

      context 'and the requestor is human' do
        before { allow(requestor).to receive(:is_human?) { true } }

        context 'and the tasked has tasks for the requestor' do
          before { allow(Domain::DoesTaskingExist).to receive(:[]) { true } }

          it { should be true }
        end

        context 'and the tasked has no tasks for the requestor' do
          before { allow(Domain::DoesTaskingExist).to receive(:[]) { false } }

          it { should be false }
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
      role = Role::CreateUserRole[requestor.entity_user]
      Tasks::CreateTasking.call(task: tasked.task_step.task, role: role)

      [:read, :create, :update, :destroy, :mark_completed].each do |allowed_action|
        expect(TaskedAccessPolicy.action_allowed?(allowed_action, requestor, tasked)).to be_truthy
      end
    end
  end
end
