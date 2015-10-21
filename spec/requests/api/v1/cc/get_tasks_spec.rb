require "rails_helper"

describe "Get CC Tasks", type: :request, api: true, version: :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create(:user) }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create(:user) }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_2.id }

  let!(:anon_user)        { User::User.anonymous }
  let!(:anon_user_token) { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: anon_user.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token, application: application }

  def get_route(cnx_book_id:, cnx_page_id:)
    "/api/cc/tasks/#{cnx_book_id}/#{cnx_page_id}"
  end

  describe "#show" do
    it "should create on first request and not again" do
      expect{
        api_get(get_route(cnx_book_id: 'foo', cnx_page_id: 'bar'), user_1_token)
      }.to change{Tasks::Models::Task.count}.by(1)

      cc_task = Tasks::Models::Task.order{created_at.desc}.first

      expect(response.code).to eq '200'
      expect(response.body_as_hash).to include(id: cc_task.id.to_s)
      expect(response.body_as_hash).to include(title: cc_task.title)
      expect(response.body_as_hash).to have_key(:steps)
      expect(response.body_as_hash[:steps].length).to eq 3

      expect{
        api_get(get_route(cnx_book_id: 'foo', cnx_page_id: 'bar'), user_1_token)
      }.to change{Tasks::Models::Task.count}.by(0)

      expect(response.body_as_hash).to include(id: cc_task.id.to_s)
    end

    it 'gets different tasks for different users' do
      expect{
        api_get(get_route(cnx_book_id: 'foo', cnx_page_id: 'bar'), user_1_token)
      }.to change{Tasks::Models::Task.count}.by(1)

      cc_task = Tasks::Models::Task.order{created_at.desc}.first
      expect(response.body_as_hash).to include(id: cc_task.id.to_s)

      expect{
        api_get(get_route(cnx_book_id: 'foo', cnx_page_id: 'bar'), user_2_token)
      }.to change{Tasks::Models::Task.count}.by(1)

      cc_task2 = Tasks::Models::Task.order{created_at.desc}.first
      expect(response.body_as_hash).to include(id: cc_task2.id.to_s)

      expect(cc_task2.id).not_to eq cc_task.id
    end

    it 'returns 403 when user is anonymous' do
      expect {
        api_get(get_route(cnx_book_id: 'foo', cnx_page_id: 'bar'), anon_user_token)
      }.to change{Tasks::Models::Task.count}.by(0)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when user is not a human' do
      expect {
        api_get(get_route(cnx_book_id: 'foo', cnx_page_id: 'bar'), userless_token)
      }.to change{Tasks::Models::Task.count}.by(0)
      expect(response).to have_http_status(:forbidden)
    end
  end

end
