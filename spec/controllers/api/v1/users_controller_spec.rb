require "rails_helper"

module Api::V1
  describe UsersController, :type => :controller, :api => true, :version => :v1 do

    let!(:application)     { FactoryGirl.create :doorkeeper_application }
    let!(:user)          { FactoryGirl.create :user, :agreed_to_terms }
    let!(:admin)      { FactoryGirl.create :user, :administrator, :agreed_to_terms }

    let!(:user_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application, 
                                              resource_owner_id: user.id }

    let!(:admin_token)    { FactoryGirl.create :doorkeeper_access_token,
                                               application: application, 
                                               resource_owner_id: admin.id }

    let!(:application_token) { FactoryGirl.create :doorkeeper_access_token, 
                                                  application: application, 
                                                  resource_owner_id: nil }

    context "GET users" do
      before(:each) do
        100.times do
          u = FactoryGirl.build(:user)
          next if u.last_name == "Doe"
          u.save!
        end

        @john_doe = FactoryGirl.create :user, first_name: "John",
                                              last_name: "Doe",
                                              username: "doejohn"
        @jane_doe = FactoryGirl.create :user, first_name: "Jane",
                                              last_name: "Doe",
                                              username: "doejane"
        @john_doe.account.reload
        @jane_doe.account.reload

        @users_count = User.count
      end

      it "returns no results if the maximum number of results is exceeded" do
        api_get :index, admin_token, parameters: {q: ''}
        expect(response).to have_http_status(:ok)

        expected_response = {
          num_matching_users: @users_count,
          page: 0,
          per_page: 20,
          order_by: 'username ASC',
          users: []
        }.to_json

        expect(response.body).to eq(expected_response)
      end

      it "returns single results" do
        api_get :index, application_token, parameters: {q: 'first_name:jOhN last_name:dOe'}
        expect(response).to have_http_status(:ok)

        expected_response = {
          num_matching_users: 1,
          page: 0,
          per_page: 20,
          order_by: 'username ASC',
          users: [
            {
              id: @john_doe.account.openstax_uid,
              username: @john_doe.username,
              first_name: @john_doe.first_name,
              last_name: @john_doe.last_name,
              full_name: @john_doe.full_name,
              title: @john_doe.title
            }
          ]
        }.to_json

        expect(response.body).to eq(expected_response)
      end

      it "returns multiple results" do
        api_get :index, user_token, parameters: {q: 'last_name:DoE'}
        expect(response).to have_http_status(:ok)

        expected_response = {
          num_matching_users: 2,
          page: 0,
          per_page: 20,
          order_by: 'username ASC',
          users: [
            {
              id: @jane_doe.account.openstax_uid,
              username: @jane_doe.username,
              first_name: @jane_doe.first_name,
              last_name: @jane_doe.last_name,
              full_name: @jane_doe.full_name,
              title: @jane_doe.title
            },
            {
              id: @john_doe.account.openstax_uid,
              username: @john_doe.username,
              first_name: @john_doe.first_name,
              last_name: @john_doe.last_name,
              full_name: @john_doe.full_name,
              title: @john_doe.title
            }
          ]
        }.to_json

        expect(response.body).to eq(expected_response)
      end

      it "sorts by multiple fields in different directions" do
        api_get :index, user_token, parameters: {q: 'username:doe',
                                                 order_by: "first_name DESC, last_name"}
        expect(response).to have_http_status(:ok)

        expected_response = {
          num_matching_users: 2,
          page: 0,
          per_page: 20,
          order_by: 'first_name DESC, last_name ASC',
          users: [
            {
              id: @john_doe.account.openstax_uid,
              username: @john_doe.username,
              first_name: @john_doe.first_name,
              last_name: @john_doe.last_name,
              full_name: @john_doe.full_name,
              title: @john_doe.title
            },
            {
              id: @jane_doe.account.openstax_uid,
              username: @jane_doe.username,
              first_name: @jane_doe.first_name,
              last_name: @jane_doe.last_name,
              full_name: @jane_doe.full_name,
              title: @jane_doe.title
            }
          ]
        }.to_json

        expect(response.body).to eq(expected_response)
      end
    end

    context "GET user" do
      it "returns the current User's info" do
        api_get :show, user_token
        expect(response).to have_http_status(:ok)

        expected_response = {
          id: user.id,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          title: user.title
        }.to_json
        
        expect(response.body).to eq(expected_response)
      end

      it "ignores id parameters" do
        api_get :show, user_token, parameters: {id: admin.id, user_id: admin.id}
        expect(response).to have_http_status(:ok)
        
        expected_response = {
          id: user.id,
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          title: user.title
        }.to_json
        
        expect(response.body).to eq(expected_response)
      end
    end

    context "PATCH user" do
      it "updates the current User's profile" do
        api_put :update, user_token, raw_post_data: {first_name: "Jerry", last_name: "Mouse"}
        expect(response).to have_http_status(:no_content)
        user.reload
        expect(user.first_name).to eq 'Jerry'
        expect(user.last_name).to eq 'Mouse'
      end

      it "ignores id parameters" do
        api_put :update, user_token, raw_post_data: {first_name: "Jerry", last_name: "Mouse"}, parameters: {id: admin.id, user_id: admin.id}
        expect(response).to have_http_status(:no_content)
        user.reload
        admin.reload
        expect(user.first_name).to eq 'Jerry'
        expect(user.last_name).to eq 'Mouse'
        expect(admin.first_name).not_to eq 'Jerry'
        expect(admin.last_name).not_to eq 'Mouse'
      end
    end

    context "DELETE user" do
      it "deactivates the current User's account" do
        api_delete :destroy, user_token
        expect(response).to have_http_status(:no_content)
        user.reload
        expect(user.is_deleted?).to eq true
      end

      it "ignores id parameters" do
        api_delete :destroy, user_token, parameters: {id: admin.id, user_id: admin.id}
        expect(response).to have_http_status(:no_content)
        user.reload
        admin.reload
        expect(user.is_deleted?).to eq true
        expect(admin.is_deleted?).to eq false
      end
    end

    context "GET tasks" do
      it "should let a user retrieve their non-existent tasks" do
        api_get :tasks, user_token
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq({
          total_count: 0,
          items: []
        }.to_json)
      end
    end

  end
end
