require 'rails_helper'
require 'tasks/sprint/sprint_007/main'

RSpec.describe Sprint007::Main, :type => :request, version: :v1, vcr: VCR_OPTS do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:jimmy)           { FactoryGirl.create :user }
  let!(:jimmy_token)     { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: jimmy.id }

  it "doesn't catch on fire" do
    expect(Sprint007::Main.call(username_or_user: "frank").errors).to be_empty

    frank_token = FactoryGirl.create(:doorkeeper_access_token, 
                                     application: application, 
                                     resource_owner_id: User.first.id)

    api_get '/api/courses/1/readings', frank_token
    expect(response).to have_http_status(:success)
  end

end
