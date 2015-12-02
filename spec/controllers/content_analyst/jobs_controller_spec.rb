require 'rails_helper'

RSpec.describe ContentAnalyst::JobsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      controller.sign_in(FactoryGirl.create(:user, :content_analyst))

      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
