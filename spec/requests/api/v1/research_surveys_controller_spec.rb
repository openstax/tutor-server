require "rails_helper"

RSpec.describe Api::V1::ResearchSurveysController, type: :request, api: true, version: :v1 do
  let(:application)       { FactoryBot.create :doorkeeper_application }
  let(:period)            { FactoryBot.create :course_membership_period }

  let(:student_user)      { FactoryBot.create(:user_profile) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }

  let(:student_token)     { FactoryBot.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }

  let(:other_user)        { FactoryBot.create(:user_profile) }
  let(:other_user_token)  { FactoryBot.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: other_user.id }

  let(:survey)    { FactoryBot.create(:research_survey, student: student) }

  context "#update" do
    context "with correct student user" do
      it 'updates survey' do
        api_put api_research_survey_url(survey.id), student_token,
                params:  { response: { foo: 'bar' } }.to_json

        expect(response).to have_http_status(:no_content)
        expect(survey.reload.survey_js_response).to eq({'foo' => 'bar'})
        expect(survey.completed_at).not_to be_nil
      end

    end

    context "with an invalid user" do
      it "gives 403" do
        expect {
          api_put api_research_survey_url(survey.id), other_user_token,
                  params: { response: { are_you_evil: true } }.to_json
        }.to raise_error(SecurityTransgression)
      end
    end

    context 'with an already completed survey' do
      before do
        survey.update_attributes!(
          survey_js_response: { ima_undecided: false },
          completed_at: Time.new('2018-01-01')
        )
      end

      it 'will update again' do
        api_put api_research_survey_url(survey.id), student_token,
                params: { response: { ima_undecided: true } }.to_json

        expect(survey.reload.survey_js_response).to eq('ima_undecided' => true)
        expect(survey.completed_at).to be_between(Time.now - 10.second, Time.now)
      end
    end
  end
end
