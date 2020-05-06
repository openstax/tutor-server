require 'rails_helper'

RSpec.describe Research::SurveyPlansController, type: :request do
  before(:all) do
    @researcher = FactoryBot.create :user_profile, :researcher
    @survey_plan = FactoryBot.create :research_survey_plan
  end

  before { sign_in! @researcher }

  context 'GET #index' do
    it 'responds with success' do
      get research_survey_plans_url

      expect(response).to be_ok
    end
  end

  context 'POST #export' do
    it 'calls Research::ExportAndUploadSurveyData and redirects to #index' do
      expect(Research::ExportAndUploadSurveyData).to(
        receive(:perform_later).with(survey_plan: @survey_plan, filename: kind_of(String))
      )

      post export_research_survey_plan_url(@survey_plan.id)

      expect(response).to redirect_to research_survey_plans_url
    end

    it "raises RecordNotFound and does not export when the survey_plan is not found" do
      expect(Research::ExportAndUploadSurveyData).not_to receive(:perform_later)

      expect do
        post export_research_survey_plan_url(@survey_plan.id + 1)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
