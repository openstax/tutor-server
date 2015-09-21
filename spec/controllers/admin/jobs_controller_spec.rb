require 'rails_helper'

RSpec.describe Admin::JobsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      admin = FactoryGirl.create(:user_profile_profile, :administrator)
      stub_current_user(admin)

      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
