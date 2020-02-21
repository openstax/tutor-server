require 'rails_helper'

RSpec.describe TeacherStudentAccessPolicy, type: :access_policy do
  let(:course)          { FactoryBot.create :course_profile_course }
  let(:period)          { FactoryBot.create :course_membership_period, course: course }
  let(:user)            { FactoryBot.create :user_profile }
  let!(:teacher)        { AddUserAsCourseTeacher[user: user, course: course].teacher }
  let(:teacher_student) { CreateOrResetTeacherStudent[user: user, period: period].teacher_student }

  subject(:action_allowed) { described_class.action_allowed?(action, requestor, teacher_student) }

  context 'when the action is show' do
    let(:action) { :show }

    context 'and the requestor is the same user' do
      let(:requestor) { user }

      context 'and the requestor is human' do
        context 'and the requestor is a course teacher' do
          let(:requestor) { user }

          context 'and the period is not archived' do
            it { should eq true }
          end

          context 'and the period is archived' do
            before { allow(period).to receive(:archived?) { true } }

            it { should eq false }
          end
        end

        context 'and the requestor is not a course teacher' do
          before { teacher.destroy }

          it { should eq false }
        end
      end

      context 'and the requestor is not human' do
        before { allow(requestor).to receive(:is_human?) { false } }

        it { should eq false }
      end
    end

    context 'and the requestor is someone else' do
      let(:requestor) { FactoryBot.create :user_profile }

      it { should eq false }
    end
  end

  context "when the action is made_up" do
    let(:action)    { :made_up }
    let(:requestor) { user }

    it { should eq false }
  end
end
