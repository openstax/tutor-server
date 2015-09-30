require 'rails_helper'

RSpec.describe CustomerService::ConsoleController do
  describe 'GET #index' do
    it 'responds with success' do
      profile = FactoryGirl.create(:user_profile, :customer_service)
      strategy = User::Strategies::Direct::User.new(profile)
      customer_service = User::User.new(strategy: strategy)

      controller.sign_in(customer_service)

      get :index

      expect(response).to be_ok
    end
  end
end
