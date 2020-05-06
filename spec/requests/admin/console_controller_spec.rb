require 'rails_helper'

RSpec.describe Admin::ConsoleController, type: :request do
  context 'GET #index' do
    it 'responds with success' do
      admin = FactoryBot.create(:user_profile, :administrator)

      sign_in! admin

      get admin_root_url

      expect(response).to be_ok
    end
  end
end
