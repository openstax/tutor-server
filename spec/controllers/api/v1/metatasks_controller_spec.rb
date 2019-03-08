require "rails_helper"

RSpec.describe Api::V1::MetatasksController,
               type: :controller, api: true,
               version: :v1, speed: :medium do

  let(:course)             { FactoryBot.create :course_profile_course }
  let(:period)             { FactoryBot.create :course_membership_period, course: course }

  let(:application)        { FactoryBot.create :doorkeeper_application }
  let(:user_1)             { FactoryBot.create(:user) }
  let(:task_plan_1)        { FactoryBot.create :tasks_task_plan, owner: course }
  let!(:user_1_role) { AddUserAsPeriodStudent[user: user_1, period: period] }
  let!(:tasking_1)   { FactoryBot.create :tasks_tasking, role: user_1_role, task: task_1 }
  let(:user_1_token)       do
    FactoryBot.create :doorkeeper_access_token, application: application,
                      resource_owner_id: user_1.id
  end
  let(:task_1) do
    FactoryBot.create :tasks_task, title: 'A Task Title',
                      task_plan: task_plan_1,
                      step_types: [:tasks_tasked_reading, :tasks_tasked_exercise]
  end

  context "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: {id: task_1.id}
      expect(response.code).to eq '200'
      expect(response.body_as_hash).to include(id: task_1.id.to_s)
      expect(response.body_as_hash).to include(title: 'A Task Title')
      expect(response.body_as_hash).to have_key(:metatask_steps)
      expect(response.body_as_hash[:metatask_steps][0]).to include(type: 'reading')
      expect(response.body_as_hash[:metatask_steps][1]).to include(type: 'exercise')
    end
  end
end
