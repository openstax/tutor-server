require 'rails_helper'

RSpec.describe TeacherAccessPolicy, type: :access_policy do
  let(:requestor)    { FactoryBot.create(:user) }
  let(:course)       { FactoryBot.create :course_profile_course }
  let(:teacher_user) { FactoryBot.create(:user) }
  let(:teacher)      { AddUserAsCourseTeacher[user: teacher_user, course: course].teacher }

  subject(:action_allowed) { described_class.action_allowed?(action, requestor, teacher) }

  context 'when the action is show' do
    let(:action) { :show }

    context 'and the requestor is human' do
      context 'and the requestor is the same user' do
        before { allow(requestor).to receive(:id) { teacher_user.id } }

        context 'and the teacher is not deleted' do
          it { should eq true }
        end

        context 'and the teacher is deleted' do
          before { allow(teacher).to receive(:deleted?) { true } }

          it { should eq false }
        end
      end

      context 'and the requestor is not the same user' do
        it { should eq false }
      end
    end

    context 'and the requestor is not human' do
      before { allow(requestor).to receive(:is_human?) { false } }

      it { should eq false }
    end
  end

  context 'when the action is destroy' do
    let(:action) { :destroy }

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

  context "when the action is :made_up" do
    let(:action) { :made_up }

    it { should eq false }
  end
end
