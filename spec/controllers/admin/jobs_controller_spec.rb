require 'rails_helper'

RSpec.describe Admin::JobsController, type: :controller do

  let!(:admin) { FactoryGirl.create(:user, :administrator) }

  context "GET #index" do
    it "returns http success" do
      controller.sign_in(admin)

      get :index
      expect(response).to have_http_status(:success)
    end
  end

  context "GET #show" do
    let!(:job) { Lev::BackgroundJob.create }

    it "returns http success" do
      controller.sign_in(admin)

      get :show, id: job.id
      expect(response).to have_http_status(:success)
    end
  end

end
