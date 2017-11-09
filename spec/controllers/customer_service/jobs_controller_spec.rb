require 'rails_helper'

RSpec.describe CustomerService::JobsController, type: :controller do

  let(:customer_service) { FactoryBot.create(:user, :customer_service) }

  context "GET #index" do
    it "returns http success" do
      controller.sign_in(customer_service)

      get :index
      expect(response).to have_http_status(:success)
    end
  end

  context "GET #show" do
    let(:job) { Jobba.create! }

    it "returns http success" do
      controller.sign_in(customer_service)

      get :show, id: job.id
      expect(response).to have_http_status(:success)
    end

    it "raises ActionController::RoutingError if the job does not exist" do
      controller.sign_in(customer_service)

      expect{ get :show, id: 42 }.to raise_error(ActionController::RoutingError)
    end
  end

end
