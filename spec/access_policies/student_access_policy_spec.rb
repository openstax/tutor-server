require 'rails_helper'

RSpec.describe StudentAccessPolicy, type: :access_policy do
  let(:requestor)    { FactoryGirl.create :user_profile }
  let(:course)       { Entity::Course.create }
  let(:period)       { CreatePeriod[course: course] }
  let(:student_user) { FactoryGirl.create(:user_profile).entity_user }
  let(:student_role) {
    role = Entity::Role.create
    Role::Models::User.create!(user: student_user, role: role)
    role
  }
  let(:student)      { CourseMembership::AddStudent[role: student_role, period: period] }

  subject(:action_allowed) do
    StudentAccessPolicy.action_allowed?(action, requestor, student)
  end

  [:create, :update, :destroy].each do |allowed_action|
    context "when the action is #{allowed_action}" do
      let(:action) { allowed_action }

      context 'and the requestor is human' do
        # already true for User

        context 'and the requestor is a course teacher' do
          before { allow(UserIsCourseTeacher).to receive(:[]) { true } }

          it { should be true }
        end

        context 'and the requestor is not a course teacher' do
          before { allow(UserIsCourseTeacher).to receive(:[]) { false } }

          it { should be false }
        end
      end

      context 'and the requestor is not human' do
        before { allow(requestor).to receive(:is_human?) { false } }

        it { should be false }
      end
    end
  end

  context "when the action is :made_up" do
    let(:action) { :made_up }

    it { should be false }
  end
end
