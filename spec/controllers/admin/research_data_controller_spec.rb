require 'rails_helper'

RSpec.describe Admin::ResearchDataController, type: :controller do
  let(:admin) { FactoryGirl.create(:user, :administrator) }

  before { controller.sign_in(admin) }

  context 'GET #index' do
    it 'responds with success' do
      get :index

      expect(response).to be_ok
    end
  end

  context 'POST #create' do
    it 'calls ExportAndUploadResearchData and redirects to #index' do
      expect(ExportAndUploadResearchData).to receive(:perform_later)

      post :create

      expect(response).to redirect_to admin_research_data_path
    end
  end
end
