require 'rails_helper'

RSpec.describe ResearchSurveyAccessPolicy, type: :access_policy do
  let(:course)       { FactoryBot.create :course_profile_course }
  let(:period)       { FactoryBot.create :course_membership_period, course: course }
  let(:student_user) { FactoryBot.create(:user_profile) }
  let(:student)      { AddUserAsPeriodStudent[user: student_user, period: period].student }

  let(:requestor) { FactoryBot.create(:user_profile) } # not the 'student_user'
  let(:survey)    { FactoryBot.create(:research_survey, student: student) }

  subject(:action_allowed) {
    described_class.action_allowed?(action, requestor, survey)
  }

  context 'when the action is complete' do
    let(:action) { :complete }
    context 'and the requestor is anonymous' do
      before { allow(requestor).to receive(:is_human?) { false } }
      it { should eq false }
    end
    context 'and the requestor is human' do
      context 'but not the assigned user' do
        it { should eq false }
      end
      context 'and the requestor is user who was assigned the survey' do
        let(:requestor) { student_user }
        it { should eq true }
      end
    end
  end

end
