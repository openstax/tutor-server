require 'rails_helper'

RSpec.describe Admin::JobsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      profile = FactoryGirl.create(:user_profile, :administrator)
      strategy = User::Strategies::Direct::User.new(profile)
      admin = User::User.new(strategy: strategy)
      stub_current_user(admin)

      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
