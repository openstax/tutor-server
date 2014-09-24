require 'rails_helper'

RSpec.describe StaticPagesController, :type => :controller do

  describe "GET home" do
    it "returns http success" do
      get :home
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET copyright" do
    it "returns http success" do
      get :copyright
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET terms" do
    it "returns http success" do
      get :terms
      expect(response).to have_http_status(:success)
    end
  end

end
