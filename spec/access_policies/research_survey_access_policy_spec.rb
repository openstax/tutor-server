require 'rails_helper'

RSpec.describe ResearchSurveyAccessPolicy, type: :access_policy, speed: :medium do
  let(:requestor)    { FactoryBot.create(:research_survey) }
  let(:student_user) { FactoryBot.create(:user) }
  subject(:action_allowed) { described_class.action_allowed?(action, requestor, student) }

  context 'when the action is complete' do
    let(:action) { :complete }
    context 'and the requestor is human' do
      context 'and the requestor is currect user' do
        before { allow(requestor).to receive(:id) { student_user.id } }

        it { should eq true }

      end
    end
  end


end
