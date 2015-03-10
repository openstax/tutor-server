require "rails_helper"

describe Api::V1::TaskStepsController, :type => :controller, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
                                              application: application }

  let!(:task_step)       { FactoryGirl.create :task_step, title: 'title', url: 'url', content: 'content' }
  let!(:tasking)         { FactoryGirl.create :tasking, taskee: user_1, task: task_step.task }         

  let!(:tasked_exercise) { FactoryGirl.create :tasked_exercise }                                   

  describe "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: {task_id: task_step.task.id, id: task_step.id}
      expect(response.code).to eq '200'

      expect(JSON.parse(response.body)).to eq({
        id: task_step.id,
        type: 'reading',
        title: 'title',
        is_completed: false,
        content_url: 'url',
        content_html: 'content'
      }.stringify_keys)
    end
  end

  describe "#completed" do
    it "should allow marking completion of reading steps by the owner" do
      tasked = create_tasked(:tasked_reading, user_1)
      api_put :completed, user_1_token, parameters: {task_id: tasked.task_step.task.id, id: tasked.task_step.id}
      expect(response.code).to eq '200'
      expect(tasked.task_step(true).completed?).to be_truthy
    end

    it "should not allow marking completion of reading steps by random user" do
      tasked = create_tasked(:tasked_reading, user_1)
      expect{
        api_put :completed, user_2_token, parameters: {task_id: tasked.task_step.task.id, id: tasked.task_step.id}  
      }.to raise_error
      expect(tasked.task_step(true).completed?).to be_falsy
    end

    it "should allow marking completion of exercise steps" do
      tasked = create_tasked(:tasked_exercise, user_1)
      api_put :completed, user_1_token, parameters: {task_id: tasked.task_step.task.id, id: tasked.task_step.id}
      expect(response.code).to eq '200'
      expect(tasked.task_step(true).completed?).to be_truthy
    end
  end

  describe "PATCH update" do
   
    let!(:tasked) { create_tasked(:tasked_exercise, user_1) }
    let!(:id_parameters) { { task_id: tasked.task_step.task.id, id: tasked.task_step.id } }

    it "updates the free response of an exercise" do
      api_put :update, user_1_token, parameters: id_parameters, 
              raw_post_data: { free_response: "Ipsum lorem" }

      expect(response).to have_http_status(:success)
      expect(tasked.reload.free_response).to eq "Ipsum lorem"
    end

    it "updates the selected answer of an exercise" do
      tasked.free_response = "Ipsum lorem"
      tasked.save!

      api_put :update, user_1_token, parameters: id_parameters, 
              raw_post_data: { answer_id: tasked.answers[0][0]['id'] }

      expect(response).to have_http_status(:success)
      expect(tasked.reload.answer_id).to eq tasked.answers[0][0]['id']
    end

    it "does not update the answer if the free response is not set" do
      api_put :update, user_1_token, parameters: id_parameters, 
              raw_post_data: { answer_id: tasked.answers[0][0]['id'] }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tasked.reload.answer_id).to be_nil
    end

  end

  # TODO: could replace with FactoryGirl calls like in TaskedExercise factory examples
  def create_tasked(type, owner)
    tasked = FactoryGirl.create(type)
    tasking = FactoryGirl.create(:tasking, taskee: owner, task: tasked.task_step.task)
    tasked
  end

end
