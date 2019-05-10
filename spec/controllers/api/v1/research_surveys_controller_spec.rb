require "rails_helper"

RSpec.describe Api::V1::ResearchSurveysController, type: :controller, api: true, version: :v1 do

  let(:application)       { FactoryBot.create :doorkeeper_application }
  let(:period)            { FactoryBot.create :course_membership_period }

  let(:student_user)      { FactoryBot.create(:user) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }

  let(:student_token)     { FactoryBot.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }

  let(:other_user)        { FactoryBot.create(:user) }
  let(:other_user_token)  { FactoryBot.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: other_user.id }

  let(:survey)    { FactoryBot.create(:research_survey, student: student) }

  context "#update" do
    context "with correct student user" do

      it 'updates survey' do
        api_put :update, student_token,
                params: { id: survey.id },
                body: { response: { foo: 'bar' } }

        expect(response).to have_http_status(:no_content)
        expect(survey.reload.survey_js_response).to eq({'foo' => 'bar'})
        expect(survey.completed_at).not_to be_nil
      end

    end

    context "with an invalid user" do
      it "gives 403" do
        expect {
          api_put :update, other_user_token,
                  params: { id: survey.id },
                  body: { response: { are_you_evil: true } }
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
        api_put :update, student_token,
                params: { id: survey.id },
                body: { response: { ima_undecided: true } }

        expect(survey.reload.survey_js_response).to eq('ima_undecided' => true)
        expect(survey.completed_at).to be_between(Time.now - 10.second, Time.now)
      end
    end

  end

end
