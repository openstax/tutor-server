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

  describe "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: {task_id: task_step.task.id, id: task_step.id}
      expect(response.code).to eq '200'
      expect(response.body).to eq({
        id: task_step.id,
        type: 'reading',
        title: 'title',
        is_completed: false,
        content_url: 'url',
        content_html: 'content'
      }.to_json)
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

    it "should allow marking completion of interactive steps" do
      tasked = create_tasked(:tasked_interactive, user_1)
      api_put :completed, user_1_token, parameters: {task_id: tasked.task_step.task.id, id: tasked.task_step.id}
      expect(response.code).to eq '200'
      expect(tasked.task_step(true).completed?).to be_truthy
    end

    it "should allow marking completion of exercise steps" do
      tasked = create_tasked(:tasked_exercise, user_1)
      api_put :completed, user_1_token, parameters: {task_id: tasked.task_step.task.id, id: tasked.task_step.id}
      expect(response.code).to eq '200'
      expect(tasked.task_step(true).completed?).to be_truthy
    end
  end

  def create_tasked(type, owner)
    tasked = FactoryGirl.create(type)
    tasking = FactoryGirl.create(:tasking, taskee: owner, task: tasked.task_step.task)
    tasked
  end

end
