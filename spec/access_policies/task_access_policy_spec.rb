require 'rails_helper'

RSpec.describe TaskAccessPolicy, type: :access_policy do
  let(:requestor) { FactoryGirl.create(:user_profile_profile) }
  let(:task) { FactoryGirl.create(:tasks_task) }

  subject(:action_allowed) do
    TaskAccessPolicy.action_allowed?(action, requestor, task)
  end

  context 'when the action is :read' do
    let(:action) { :read }

    context 'and the requestor is human' do
      # already true for User

      context 'and the requestor has taskings in the task' do
        before { allow(DoesTaskingExist).to receive(:[]) { true } }

        context "and the task's open date has passed" do
          before { allow(task).to receive(:past_open?) { true } }

          it { should be true }
        end

        context "and the task's open date has not passed" do
          before { allow(task).to receive(:past_open?) { false } }

          it { should be false }
        end
      end

      context 'and the requestor has no taskings in the task' do
        before { allow(DoesTaskingExist).to receive(:[]) { false } }

        it { should be false }
      end

      context 'and the requestor is a course teacher' do
        before { allow(DoesTaskingExist).to receive(:[]) { false }
                 allow(UserIsCourseTeacher).to receive(:[]) { true } }

        it { should be true }
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
