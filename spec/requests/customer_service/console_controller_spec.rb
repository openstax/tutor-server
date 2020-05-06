require 'rails_helper'

RSpec.describe CustomerService::ConsoleController, type: :request do
  context 'GET #index' do
    it 'responds with success' do
      sign_in! FactoryBot.create(:user_profile, :customer_service)

      get customer_service_root_url

      expect(response).to be_ok
    end
  end
end
