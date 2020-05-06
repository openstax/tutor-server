require 'rails_helper'

RSpec.describe ContentAnalyst::JobsController, type: :request do
  let(:content_analyst) { FactoryBot.create(:user_profile, :content_analyst) }

  context "GET #show" do
    let(:job) { Jobba.create! }

    it "returns http success" do
      sign_in! content_analyst

      get content_analyst_job_url(job.id)
      expect(response).to have_http_status(:success)
    end

    it "raises ActionController::RoutingError if the job does not exist" do
      sign_in! content_analyst

      expect { get content_analyst_job_url(42) }.to raise_error(ActionController::RoutingError)
    end
  end
end
