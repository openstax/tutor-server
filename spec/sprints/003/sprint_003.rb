require 'rails_helper'

RSpec.describe Sprint003, :type => :routine do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:jimmy)           { FactoryGirl.create :user }
  let!(:jimmy_token)     { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: jimmy.id }

  it "doesn't catch on fire" do
    result = Sprint003::Main.call("frank")
  end

  it "produces the correct user tasks JSON" do
    Sprint003::Main.call(jimmy)

    api_get :tasks, jimmy_token
    expect(response.code).to eq('200')
    expect(response.body).to eq({
      total_count: 1,
      items: []
    }.to_json)
  end

end



