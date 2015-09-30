require 'rails_helper'

RSpec.describe CustomerService::JobsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      profile = FactoryGirl.create(:user_profile, :customer_service)
      strategy = User::Strategies::Direct::User.new(profile)
      customer_service = User::User.new(strategy: strategy)
      controller.sign_in(customer_service)

      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
