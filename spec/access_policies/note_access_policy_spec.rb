require 'rails_helper'

RSpec.describe NoteAccessPolicy, type: :access_policy, speed: :medium do
  let(:requestor)    { FactoryBot.create(:user_profile) }
  let(:course)       { FactoryBot.create :course_profile_course }
  let(:period)       { FactoryBot.create :course_membership_period, course: course }
  let(:student_user) { FactoryBot.create(:user_profile) }
  let(:student_role) { AddUserAsPeriodStudent[user: student_user, period: period] }

  let(:note) { FactoryBot.create :content_note, role: student_role }

  subject(:action_allowed) { described_class.action_allowed?(action, requestor, note) }

  context 'when the action is show' do
    let(:action) { :show }
    context 'and the requestor is anonymous' do
      before do
        allow(requestor).to receive(:id) { nil }
      end
      it { should eq false }
    end
  end

  context 'when the action is create' do
    let(:action) { :create }

    context 'and the requestor matches user' do
      before do
        allow(requestor).to receive(:id) { student_role.user_profile_id }
      end
      it { should eq true }
    end
  end
end
