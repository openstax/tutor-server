require 'spec_helper'
require './app/access_policies/task_access_policy'

RSpec.describe TaskAccessPolicy do
  let(:requestor) { double(:requestor, id: 1) }
  let(:task) { double(:task) }

  subject(:action_allowed) { TaskAccessPolicy.action_allowed?(action, requestor, task) }

  context 'when the action is :read' do
    let(:action) { :read }

    before do
      taskings = double(:taskings)
      allow(task).to receive(:taskings) { taskings }
      allow(taskings).to receive(:where) { filtered_taskings }
    end

    context 'and the requestor is human' do
      before { allow(requestor).to receive(:is_human?) { true } }

      context 'and the requestor has taskings in the task' do
        let(:filtered_taskings) { [double(:tasking)] }

        it { should be true }
      end

      context 'and the requestor has no taskings in the task' do
        let(:filtered_taskings) { [] }

        it { should be false }
      end
    end

    context 'and the requestor is not human' do
      before { allow(requestor).to receive(:is_human?) { false } }

      it { should be false }
    end
  end

  [:create, :update, :destroy, :made_up].each do |disallowed_action|
    context "when the action is :#{disallowed_action}" do
      let(:action) { disallowed_action }

      it { should be false }
    end
  end
end
