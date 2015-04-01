require "rails_helper"

describe Api::V1::TaskStepsController, :type => :controller, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }
  let!(:user_1_role)     { Role::GetDefaultUserRole[user_1.entity_user] }

  let!(:user_2)          { FactoryGirl.create :user }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
                                              application: application }

  let!(:task_step)       { FactoryGirl.create :tasks_task_step, title: 'title',
                                              url: 'url', content: 'content' }
  let!(:task)            { task_step.task.reload }
  let!(:tasking)         { FactoryGirl.create :tasks_tasking, role: user_1_role,
                                                        task: task.entity_task }
  let!(:tasked_exercise) {
    te = FactoryGirl.create :tasks_tasked_exercise, skip_task: true
    te.task_step.task = task
    te.task_step.save!
    te
  }

  let!(:course) { Entity::Course.create }

  describe "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: { task_id: task_step.task.id,
                                                 id: task_step.id }
      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to eq({
        id: task_step.id,
        task_id: task_step.task_id,
        type: 'reading',
        title: 'title',
        is_completed: false,
        content_url: 'url',
        content_html: 'content'
      })
    end
  end

  describe "PATCH update" do

    let!(:tasked) { create_tasked(:tasked_exercise, user_1_role) }
    let!(:id_parameters) { { task_id: tasked.task_step.task.id,
                             id: tasked.task_step.id } }

    it "updates the free response of an exercise" do
      api_put :update, user_1_token, parameters: id_parameters,
              raw_post_data: { free_response: "Ipsum lorem" }

      expect(response).to have_http_status(:success)

      expect(response.body).to(
        eq(Api::V1::TaskedExerciseRepresenter.new(tasked.reload).to_json)
      )

      expect(tasked.reload.free_response).to eq "Ipsum lorem"
    end

    it "updates the selected answer of an exercise" do
      tasked.free_response = "Ipsum lorem"
      tasked.save!

      api_put :update, user_1_token, parameters: id_parameters,
              raw_post_data: { answer_id: tasked.answers[0][0]['id'] }

      expect(response).to have_http_status(:success)

      expect(response.body).to(
        eq(Api::V1::TaskedExerciseRepresenter.new(tasked.reload).to_json)
      )

      expect(tasked.reload.answer_id).to eq tasked.answers[0][0]['id']
    end

    it "does not update the answer if the free response is not set" do
      api_put :update, user_1_token, parameters: id_parameters,
              raw_post_data: { answer_id: tasked.answers[0][0]['id'] }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tasked.reload.answer_id).to be_nil
    end

  end

  describe "#recovery" do
    it "should allow owner to recover exercises with recovery steps" do
      recovery = FactoryGirl.create :tasks_tasked_exercise
      recovery.task_step.delete
      tasked_exercise.recovery_tasked_exercise = recovery
      tasked_exercise.save!

      expect {
        api_put :recovery, user_1_token, parameters: {
          task_id: tasked_exercise.task_step.task.id,
          id: tasked_exercise.task_step.id
        }
      }.to change{tasked_exercise.task_step.task.reload.task_steps.count}
      expect(response).to have_http_status(:success)

      expect(response.body).to eq(Api::V1::TaskedExerciseRepresenter.new(
        recovery.reload
      ).to_json)

      expect(recovery.task_step.task).to eq(task)
      expect(recovery.task_step.number).to(
        eq(tasked_exercise.task_step.number + 1)
      )
    end

    it "should not allow random user to recover exercises" do
      recovery = FactoryGirl.create :tasks_tasked_exercise
      recovery.task_step.delete
      tasked_exercise.recovery_tasked_exercise = recovery
      tasked_exercise.save!
      step_count = tasked_exercise.task_step.task.task_steps.count

      expect{
        api_put :recovery, user_2_token, parameters: {
          id: tasked_exercise.task_step.id
        }
      }.to raise_error SecurityTransgression
    end

    it "should not allow owner to recover taskeds without recovery steps" do
      expect{
        api_put :recovery, user_1_token, parameters: {
          id: tasked_exercise.task_step.id
        }
      }.to change{tasked_exercise.task_step.task.reload.task_steps.count}.by(0)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "#completed" do
    it "should allow marking completion of reading steps by the owner" do
      tasked = create_tasked(:tasked_reading, user_1_role)
      api_put :completed, user_1_token, parameters: {id: tasked.task_step.id}
      expect(response).to have_http_status(:success)

      expect(response.body).to eq(Api::V1::TaskedReadingRepresenter.new(
        tasked.reload
      ).to_json)

      expect(tasked.task_step(true).completed?).to be_truthy
    end

    it "should not allow marking completion of reading steps by random user" do
      tasked = create_tasked(:tasked_reading, user_1_role)
      expect{
        api_put :completed, user_2_token, parameters: {task_id: tasked.task_step.task.id, id: tasked.task_step.id}
      }.to raise_error SecurityTransgression
      expect(tasked.task_step(true).completed?).to be_falsy
    end

    it "should allow marking completion of exercise steps" do
      tasked = create_tasked(:tasked_exercise, user_1_role).reload
      api_put :completed, user_1_token, parameters: {task_id: tasked.task_step.task.id, id: tasked.task_step.id}
      expect(response).to have_http_status(:success)

      expect(response.body).to eq(Api::V1::TaskedExerciseRepresenter.new(
        tasked.reload
      ).to_json)

      expect(tasked.task_step(true).completed?).to be_truthy
    end
  end

  describe "practice task update step" do
    it "allows updating of a step (needed to test access to legacy and SS taskings)" do
      Domain::AddUserAsCourseStudent[course: course, user: user_1.entity_user]
      task = Domain::ResetPracticeWidget[role: Entity::Role.last, condition: :fake]

      step = task.task.task_steps.first

      api_put :update, user_1_token, parameters: { id: step.id },
              raw_post_data: { free_response: "Ipsum lorem" }

      expect(response).to have_http_status(:success)
    end
  end


  # TODO: could replace with FactoryGirl calls like in TaskedExercise factory examples
  def create_tasked(type, owner)
    # Make sure the type has the tasks_ prefix
    type = type.to_s.starts_with?("tasks_") ? type : "tasks_#{type}".to_sym
    tasked = FactoryGirl.create(type)
    tasking = FactoryGirl.create(:tasks_tasking, role: owner, task: tasked.task_step.task.entity_task)
    tasked
  end

end
