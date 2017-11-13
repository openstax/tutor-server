require 'rails_helper'

RSpec.describe Admin::JobsController, type: :controller do

  let(:admin) { FactoryBot.create(:user, :administrator) }

  context "GET #index" do
    it "returns http success" do
      controller.sign_in(admin)

      get :index
      expect(response).to have_http_status(:success)
    end
  end

  context "GET #show" do
    let(:job) { Jobba.create! }

    it "returns http success if the job exists" do
      controller.sign_in(admin)

      get :show, id: job.id
      expect(response).to have_http_status(:success)
    end

    it "raises ActionController::RoutingError if the job does not exist" do
      controller.sign_in(admin)

      expect{ get :show, id: 42 }.to raise_error(ActionController::RoutingError)
    end
  end

end
