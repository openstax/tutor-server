require 'rails_helper'

RSpec.describe StaticPagesController, type: :controller do

  context "GET copyright" do
    it "returns http success" do
      get :copyright
      expect(response).to have_http_status(:success)
    end
  end

  context "GET omniauth_failure" do
    it 'sets flash and redirects to root' do
      get :omniauth_failure, params: { message: "blah" }
      expect(flash[:error]).to include "blah"
      expect(response).to redirect_to(root_path)
    end
  end

end
