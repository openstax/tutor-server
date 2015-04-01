require "rails_helper"

describe Api::V1::TaskStepsController, :type => :controller,
                                       :api => true,
                                       :version => :v1 do

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

  let!(:task_step)       { FactoryGirl.create :tasks_task_step,
                                              title: 'title',
                                              url: 'http://u.rl',
                                              content: 'content' }

  let!(:task)            { task_step.task.reload }

  let!(:tasking)         { FactoryGirl.create :tasks_tasking, role: user_1_role,
                                                        task: task.entity_task }

  let!(:tasked_exercise) {
    te = FactoryGirl.build :tasks_tasked_exercise
    te.task_step.task = task
    te.save!
    te
  }

  let!(:course)          { Entity::Course.create }

  let!(:lo)              { FactoryGirl.create :content_tag,
                                              name: 'ost-tag-lo-test-lo01' }

  let!(:tasked_exercise_with_recovery) {
    te = FactoryGirl.build(
      :tasked_exercise,
      has_recovery: true,
      content: OpenStax::Exercises::V1.fake_client
                                      .new_exercise_hash(tags: [lo.name])
                                      .to_json
    )
    te.task_step.task = task
    te.save!
    te
  }

  let!(:recovery_exercise) { FactoryGirl.create(
    :content_exercise,
    content: OpenStax::Exercises::V1.fake_client
                                    .new_exercise_hash(tags: [lo.name])
                                    .to_json
  ) }
  let!(:recovery_tagging)   { FactoryGirl.create(
    :content_exercise_tag, exercise: recovery_exercise, tag: lo
  ) }

  describe "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: { task_id: task_step.task.id,
                                                 id: task_step.id }
      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to eq({
        id: task_step.id,
        type: 'reading',
        title: 'title',
        is_completed: false,
        content_url: 'http://u.rl',
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
      expect {
        api_put :recovery, user_1_token, parameters: {
          task_id: tasked_exercise_with_recovery.task_step.task.id,
          id: tasked_exercise_with_recovery.task_step.id
        }
      }.to change{tasked_exercise_with_recovery.task_step.task
                                               .reload.task_steps.count}
      expect(response).to have_http_status(:success)

      recovery_step = tasked_exercise_with_recovery.task_step.next_by_number

      expect(response.body).to(
        eq Api::V1::TaskedExerciseRepresenter.new(recovery_step.tasked).to_json
      )

      expect(recovery_step.tasked.wrapper.los & \
             tasked_exercise_with_recovery.wrapper.los).not_to be_empty
      expect(recovery_step.task).to eq(task)
      expect(recovery_step.number).to(
        eq(tasked_exercise_with_recovery.task_step.number + 1)
      )
    end

    it "should not allow random user to recover exercises" do
      tasked_exercise.has_recovery = true
      tasked_exercise.save!
      step_count = tasked_exercise.task_step.task.task_steps.count

      expect{
        api_put :recovery, user_2_token, parameters: {
          id: tasked_exercise.task_step.id
        }
      }.to raise_error SecurityTransgression

      expect(tasked_exercise.task_step.task.reload.task_steps.count).to(
        eq step_count
      )
    end

    it "should not allow owner to recover taskeds without recovery steps" do
      expect{
        api_put :recovery, user_1_token, parameters: {
          id: tasked_exercise.task_step.id
        }
      }.not_to change{tasked_exercise.task_step.task.reload.task_steps.count}

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "#refresh" do
    it "should allow owner to refresh exercises with recovery steps" do
      expect {
        api_put :refresh, user_1_token, parameters: {
          task_id: tasked_exercise_with_recovery.task_step.task.id,
          id: tasked_exercise_with_recovery.task_step.id
        }
      }.to change{tasked_exercise_with_recovery.task_step.task
                                               .reload.task_steps.count}
      expect(response).to have_http_status(:success)

      hash = JSON.parse(response.body)
      expect(hash['refresh_step']['url']).to eq task_step.tasked.url

      recovery_step = tasked_exercise_with_recovery.task_step.next_by_number

      expect(hash['recovery_step']).to eq JSON.parse(
        Api::V1::TaskedExerciseRepresenter.new(recovery_step.tasked).to_json
      )

      expect(recovery_step.tasked.wrapper.los & \
             tasked_exercise_with_recovery.wrapper.los).not_to be_empty
      expect(recovery_step.task).to eq(task)
      expect(recovery_step.number).to(
        eq(tasked_exercise_with_recovery.task_step.number + 1)
      )
    end

    it "should not allow random user to refresh exercises" do
      tasked_exercise.has_recovery = true
      tasked_exercise.save!
      step_count = tasked_exercise.task_step.task.task_steps.count

      expect{
        api_put :refresh, user_2_token, parameters: {
          task_id: tasked_exercise.task_step.task.id,
          id: tasked_exercise.task_step.id
        }
      }.to raise_error(SecurityTransgression)

      expect(tasked_exercise.task_step.task.reload.task_steps.count).to(
        eq step_count
      )
    end

    it "should not allow owner to refresh taskeds without recovery steps" do
      tasked = create_tasked(:tasked_reading, user_1)

      step_count = tasked_exercise.task_step.task.task_steps.count

      expect{
        api_put :refresh, user_1_token, parameters: {
          task_id: tasked_exercise.task_step.task.id,
          id: tasked_exercise.task_step.id
        }
      }.not_to change{tasked_exercise.task_step.task.reload.task_steps.count}
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
