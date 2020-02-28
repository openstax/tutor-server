require 'rails_helper'

RSpec.describe Admin::ConsoleController, type: :controller do
  context 'GET #index' do
    it 'responds with success' do
      admin = FactoryBot.create(:user_profile, :administrator)

      controller.sign_in(admin)

      get :index

      expect(response).to be_ok
    end
  end
end
