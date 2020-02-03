require 'rails_helper'

RSpec.describe Research::SurveyPlansController, type: :controller do
  before(:all) do
    @researcher = FactoryBot.create :user_profile, :researcher
    @survey_plan = FactoryBot.create :research_survey_plan
  end

  before { controller.sign_in(@researcher) }

  context 'GET #index' do
    it 'responds with success' do
      get :index

      expect(response).to be_ok
    end
  end

  pending "Add more examples to #{__FILE__}"

  context 'POST #export' do
    it 'calls Research::ExportAndUploadSurveyData and redirects to #index' do
      expect(Research::ExportAndUploadSurveyData).to(
        receive(:perform_later).with(survey_plan: @survey_plan, filename: kind_of(String))
      )

      post :export, params: { id: @survey_plan.id }

      expect(response).to redirect_to research_survey_plans_path
    end

    it "raises RecordNotFound and does not export when the survey_plan is not found" do
      expect(Research::ExportAndUploadSurveyData).not_to receive(:perform_later)

      expect do
        post :export, params: { id: @survey_plan.id + 1 }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
