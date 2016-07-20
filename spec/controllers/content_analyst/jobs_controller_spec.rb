require 'rails_helper'

RSpec.describe ContentAnalyst::JobsController, type: :controller do

  let(:content_analyst) { FactoryGirl.create(:user, :content_analyst) }

  context "GET #show" do
    let(:job) { Jobba.create! }

    it "returns http success" do
      controller.sign_in(content_analyst)

      get :show, id: job.id
      expect(response).to have_http_status(:success)
    end

    it "raises ActionController::RoutingError if the job does not exist" do
      controller.sign_in(content_analyst)

      expect{ get :show, id: 42 }.to raise_error(ActionController::RoutingError)
    end
  end

end
