require 'rails_helper'

RSpec.describe Research::ConsoleController, type: :request do
  context 'GET #index' do
    it 'responds with success' do
      sign_in! FactoryBot.create(:user_profile, :researcher)

      get research_root_url

      expect(response).to be_ok
    end
  end
end
