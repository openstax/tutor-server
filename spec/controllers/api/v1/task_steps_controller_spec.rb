require "rails_helper"

describe Api::V1::TaskStepsController, :type => :controller, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  # let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
  #                                             application: application }

  let!(:task_step)       { FactoryGirl.create :task_step, title: 'title', url: 'url', content: 'content' }
  let!(:tasking)         { FactoryGirl.create :tasking, taskee: user_1, task: task_step.task }                                            

  describe "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: {task_id: task_step.task.id, id: task_step.id}
      expect(response.code).to eq '200'
      expect(response.body).to eq({
        id: task_step.id,
        type: 'reading',
        title: 'title',
        content_url: 'url',
        content_html: 'content'
      }.to_json)
    end
  end

  # describe "#show" do
  #   context "caller has an authorization token" do
  #     it "should return an ok (200) code" do
  #       api_get :show, user_1_token
  #       expect(response.code).to eq('200')
  #     end
  #   end
  #   context "caller does not have an authorization token" do
  #     it "should return a forbidden (403) code" do
  #       api_get :show, nil
  #       expect(response.code).to eq('403')
  #     end
  #   end
  #   context "caller has an application/client credentials authorization token" do
  #     it "should return a forbidden (403) code" do
  #       api_get :show, userless_token
  #       expect(response.code).to eq('403')
  #     end
  #   end
  # end

  # describe "tasks" do
  #   it "should let a user retrieve their non-existent tasks" do
  #     api_get :tasks, user_1_token
  #     expect(response.code).to eq('200')
  #     expect(response.body).to eq({
  #       total_count: 0,
  #       items: []
  #     }.to_json)
  #   end
  # end

end
