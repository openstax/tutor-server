require 'rails_helper'

RSpec.describe Admin::ConsoleController do
  describe 'GET #index' do
    it 'responds with success' do
      admin = FactoryBot.create(:user, :administrator)

      controller.sign_in(admin)

      get :index

      expect(response).to be_ok
    end
  end
end
