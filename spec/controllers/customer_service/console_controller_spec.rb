require 'rails_helper'

RSpec.describe CustomerService::ConsoleController, type: :controller do
  context 'GET #index' do
    it 'responds with success' do
      controller.sign_in(FactoryBot.create(:user, :customer_service))

      get :index

      expect(response).to be_ok
    end
  end
end
