require "rails_helper"

describe Api::V1::KlassesController, :type => :controller, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                              application: application, 
                                              resource_owner_id: user_1.id }

  context "GET show" do

    it "should let a user retrieve their non-existent tasks" do
      api_get :user, user_1_token
      expect(response.code).to eq('200')
      expect(response.body).to eq({
        total_count: 0,
        items: []
      }.to_json)
    end

  end

  pending "add some examples to #{__FILE__}"
end                                                