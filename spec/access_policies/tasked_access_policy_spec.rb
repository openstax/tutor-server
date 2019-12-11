require 'rails_helper'

RSpec.describe TaskedAccessPolicy, type: :access_policy do
  let(:period)       { FactoryBot.create(:course_membership_period) }
  let(:requestor)    { FactoryBot.create(:user_profile) }
  let(:student_role) { AddUserAsPeriodStudent[user: requestor, period: period] }
  let(:tasked)       do
    FactoryBot.create(:tasks_tasked_exercise, :with_tasking, tasked_to: student_role)
  end

  subject(:action_allowed) do
    TaskedAccessPolicy.action_allowed?(action, requestor, tasked)
  end

  [ :read, :update ].each do |allowed_action|
    context "when the action is :#{allowed_action}" do
      let(:action) { allowed_action }

      context 'and the requestor is human' do
        before { allow(requestor).to receive(:is_human?) { true } }

        context 'and the tasked is part of a task for the requestor' do
          before { allow(DoesTaskingExist).to receive(:[]) { true } }

          context "and the task's open date has not passed" do
            before { allow(tasked.task_step.task).to receive(:past_open?) { false } }

            it { should eq false }
          end

          context "and the task's open date has passed" do
            before { allow(tasked.task_step.task).to receive(:past_open?) { true } }

            it { should eq true }

            context "and the task is deleted" do
              before { allow(tasked.task_step.task).to receive(:withdrawn?) { true } }

              it { should eq action == :read }
            end

            context "and the task's close date has passed" do
              before { allow(tasked.task_step.task).to receive(:past_close?) { true } }

              it { should eq action == :read }
            end
          end
        end

        context 'and the tasked is not part of a task for the requestor' do
          before { allow(DoesTaskingExist).to receive(:[]) { false } }

          it { should eq false }
        end

        context 'and the requestor is a course teacher' do
          before do
            allow(DoesTaskingExist   ).to receive(:[]) { false }
            allow(UserIsCourseTeacher).to receive(:[]) { true  }
          end

          it { should eq action == :read }
        end
      end

      context 'and the requestor is not human' do
        before { allow(requestor).to receive(:is_human?) { false } }

        it { should eq false }
      end
    end
  end

  context 'when the action is unknown' do
    let(:action) { :unknown_fooey }

    it { should eq false }
  end

  context 'when the tasking is in the tasks subsystem' do
    it 'allows access for the taskee' do
      role = Role::CreateUserRole[requestor]
      Tasks::CreateTasking.call(task: tasked.task_step.task, role: role)

      [ :read, :update ].each do |allowed_action|
        expect(TaskedAccessPolicy.action_allowed?(allowed_action, requestor, tasked)).to be_truthy
      end
    end
  end
end
