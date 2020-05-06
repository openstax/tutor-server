require 'rails_helper'

RSpec.describe Admin::JobsController, type: :request do
  let(:admin) { FactoryBot.create(:user_profile, :administrator) }

  context "GET #index" do
    it "returns http success" do
      sign_in! admin

      get admin_jobs_url
      expect(response).to have_http_status(:success)
    end
  end

  context "GET #show" do
    let(:job) { Jobba.create! }

    it "returns http success if the job exists" do
      sign_in! admin

      get admin_job_url(job.id)
      expect(response).to have_http_status(:success)
    end

    it "raises ActionController::RoutingError if the job does not exist" do
      sign_in! admin

      expect { get admin_job_url(42) }.to raise_error(ActionController::RoutingError)
    end
  end
end
