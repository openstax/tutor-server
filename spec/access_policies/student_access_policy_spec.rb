require 'rails_helper'

RSpec.describe StudentAccessPolicy, type: :access_policy, speed: :medium do
  let(:requestor)    { FactoryBot.create(:user) }
  let(:course)       { FactoryBot.create :course_profile_course }
  let(:period)       { FactoryBot.create :course_membership_period, course: course }
  let(:student_user) { FactoryBot.create(:user) }
  let(:student)      { AddUserAsPeriodStudent[user: student_user, period: period].student }

  subject(:action_allowed) { described_class.action_allowed?(action, requestor, student) }

  context 'when the action is show' do
    let(:action) { :show }

    context 'and the requestor is human' do
      context 'and the requestor is the same user' do
        before { allow(requestor).to receive(:id) { student_user.id } }

        context 'and the student is not dropped' do
          context 'and the period is not archived' do
            it { should eq true }
          end

          context 'and the period is archived' do
            before { allow(student.period).to receive(:archived?) { true } }

            it { should eq false }
          end
        end

        context 'and the student is dropped' do
          before { allow(student).to receive(:dropped?) { true } }

          it { should eq false }
        end
      end

      context 'and the requestor is a course teacher' do
        before { AddUserAsCourseTeacher[user: requestor, course: course] }

        context 'and the student is not dropped' do
          context 'and the period is not archived' do
            it { should eq true }
          end

          context 'and the period is archived' do
            before { allow(student.period).to receive(:archived?) { true } }

            it { should eq false }
          end
        end

        context 'and the student is dropped' do
          before { allow(student).to receive(:dropped?) { true } }

          it { should eq false }
        end
      end

      context 'and the requestor is someone else' do
        it { should eq false }
      end
    end

    context 'and the requestor is not human' do
      before { allow(requestor).to receive(:is_human?) { false } }

      it { should eq false }
    end
  end

  [:create, :update, :destroy].each do |allowed_action|
    context "when the action is #{allowed_action}" do
      let(:action) { allowed_action }

      context 'and the requestor is human' do
        context 'and the requestor is a course teacher' do
          before { allow(UserIsCourseTeacher).to receive(:[]) { true } }

          it { should eq true }
        end

        context 'and the requestor is not a course teacher' do
          before { allow(UserIsCourseTeacher).to receive(:[]) { false } }

          it { should eq false }
        end
      end

      context 'and the requestor is not human' do
        before { allow(requestor).to receive(:is_human?) { false } }

        it { should eq false }
      end
    end
  end

  context "when the action is :made_up" do
    let(:action) { :made_up }

    it { should eq false }
  end
end
