require "rails_helper"

describe Api::V1::UsersController, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  describe "#show", type: :request do
    context "caller has an authorization token" do
      it "should return an ok (200) code" do
        get '/api/user',
            {format: 'json'},
            {'HTTP_AUTHORIZATION' => "Bearer #{user_1_token.token}",
             'HTTP_ACCEPT' => "application/vnd.tutor.openstax.v1"}
        expect(response.code).to eq('200')
      end
    end
    context "caller does not have an authorization token" do
      it "should return a forbidden (403) code" do
        get '/api/user',
            {format: 'json'},
            {'HTTP_ACCEPT' => "application/vnd.tutor.openstax.v1"}
        expect(response.code).to eq('403')
      end
    end
  end

  describe "tasks", :type => :controller do
    it "should let a user retrieve their non-existent tasks" do
      api_get :tasks, user_1_token
      expect(response.code).to eq('200')
      expect(response.body).to eq({
        total_count: 0,
        items: []
      }.to_json)
    end
  end

end
