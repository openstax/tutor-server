require "rails_helper"

describe Api::V1::TasksController, type: :controller, api: true, version: :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:profile_1)       { FactoryGirl.create :user_profile_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: profile_1.id }

  let!(:user_1_role)     { Role::GetDefaultUserRole[profile_1.user] }

  let!(:profile_2)       { FactoryGirl.create :user_profile_profile }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: profile_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
                                              application: application }

  let!(:task_1)          { FactoryGirl.create :tasks_task, title: 'A Task Title',
                                              step_types: [:tasks_tasked_reading,
                                                           :tasks_tasked_exercise] }
  let!(:tasking_1)       { FactoryGirl.create :tasks_tasking, role: user_1_role,
                                                              task: task_1.entity_task }

  describe "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: {id: task_1.id}
      expect(response.code).to eq '200'
      expect(response.body_as_hash).to include(id: task_1.id.to_s)
      expect(response.body_as_hash).to include(title: 'A Task Title')
      expect(response.body_as_hash).to have_key(:steps)
      expect(response.body_as_hash[:steps][0]).to include(type: 'reading')
      expect(response.body_as_hash[:steps][1]).to include(type: 'exercise')
    end

    it 'raises SecurityTransgression when user is anonymous or not a teacher' do
      expect {
        api_get :show, nil, parameters: { id: task_1.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :show, user_2_token, parameters: { id: task_1.id }
      }.to raise_error(SecurityTransgression)
    end
  end

end
