require 'rails_helper'

RSpec.describe ContentAnalyst::ConsoleController, type: :request do
  context 'GET #index' do
    it 'responds with success' do
      sign_in! FactoryBot.create(:user_profile, :content_analyst)

      get content_analyst_root_url

      expect(response).to be_ok
    end
  end
end
