require 'rails_helper'

RSpec.describe ContentAnalyst::JobsController, type: :controller do

  let!(:content_analyst) { FactoryGirl.create(:user, :content_analyst) }

  context "GET #show" do
    let!(:job) { Lev::BackgroundJob.create }

    it "returns http success" do
      controller.sign_in(content_analyst)

      get :show, id: job.id
      expect(response).to have_http_status(:success)
    end
  end

end
