require "rails_helper"

describe Api::V1::TaskStepsController, :type => :controller, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }
  let!(:user_1_role)     { Role::GetDefaultUserRole[user_1.entity_user] }

  let!(:user_2)          { FactoryGirl.create :user_profile }
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

  let!(:lo)              { FactoryGirl.create :content_tag, value: 'ost-tag-lo-test-lo01' }
  let!(:pp)              { FactoryGirl.create :content_tag, value: 'os-practice-problems' }

  let!(:tasked_exercise_with_recovery) {
    te = FactoryGirl.build(
      :tasks_tasked_exercise,
      can_be_recovered: true,
      content: OpenStax::Exercises::V1.fake_client.new_exercise_hash(tags: [lo.value]).to_json
    )
    te.task_step.task = task
    te.save!
    te
  }

  let!(:recovery_exercise) { FactoryGirl.create(
    :content_exercise,
    content: OpenStax::Exercises::V1.fake_client
                                    .new_exercise_hash(tags: [lo.value, pp.value])
                                    .to_json
  ) }
  let!(:recovery_tagging_1)   { FactoryGirl.create(
    :content_exercise_tag, exercise: recovery_exercise, tag: lo
  ) }
  let!(:recovery_tagging_2)   { FactoryGirl.create(
    :content_exercise_tag, exercise: recovery_exercise, tag: pp
  ) }

  describe "#show" do
    it "should work on the happy path" do
      api_get :show, user_1_token, parameters: { task_id: task_step.task.id, id: task_step.id }
      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to include({
        id: task_step.id.to_s,
        task_id: task_step.tasks_task_id.to_s,
        type: 'reading',
        title: 'title',
        chapter_section: task_step.tasked.chapter_section,
        is_completed: false,
        content_url: 'http://u.rl',
        content_html: 'content',
        related_content: a_kind_of(Array)
      })
    end
  end

  describe "PATCH update" do

    let!(:tasked) { create_tasked(:tasked_exercise, user_1_role) }
    let!(:id_parameters) { { task_id: tasked.task_step.task.id, id: tasked.task_step.id } }

    it "updates the free response of an exercise" do
      api_put :update, user_1_token, parameters: id_parameters,
              raw_post_data: { free_response: "Ipsum lorem" }

      expect(response).to have_http_status(:success)

      expect(response.body).to eq(
        Api::V1::Tasks::TaskedExerciseRepresenter.new(tasked.reload).to_json
      )

      expect(tasked.reload.free_response).to eq "Ipsum lorem"
    end

    it "updates the selected answer of an exercise" do
      tasked.free_response = "Ipsum lorem"
      tasked.save!
      answer_id = tasked.answer_ids.first

      api_put :update, user_1_token,
              parameters: id_parameters, raw_post_data: { answer_id: answer_id.to_s }

      expect(response).to have_http_status(:success)

      expect(response.body).to eq(
        Api::V1::Tasks::TaskedExerciseRepresenter.new(tasked.reload).to_json
      )

      expect(tasked.reload.answer_id).to eq answer_id
    end

    it "does not update the answer if the free response is not set" do
      answer_id = tasked.answer_ids.first

      api_put :update, user_1_token,
              parameters: id_parameters, raw_post_data: { answer_id: answer_id.to_s }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tasked.reload.answer_id).to be_nil
    end

  end

  describe "#recovery" do
    it "should allow owner to recover exercises with recovery steps" do
      expect {
        api_put :recovery, user_1_token, parameters: {
          id: tasked_exercise_with_recovery.task_step.id
        }
      }.to change{tasked_exercise_with_recovery.task_step.task
                                               .reload.task_steps.count}
      expect(response).to have_http_status(:success)

      recovery_step = tasked_exercise_with_recovery.task_step.next_by_number
      tasked = recovery_step.tasked

      expect(response.body).to(
        eq Api::V1::Tasks::TaskedExerciseRepresenter.new(tasked).to_json
      )

      expect(tasked.los & tasked_exercise_with_recovery.parser.los).not_to be_empty
      expect(recovery_step.task).to eq(task)
      expect(recovery_step.number).to(
        eq(tasked_exercise_with_recovery.task_step.number + 1)
      )
    end

    it "should not allow random user to recover exercises" do
      step_count = tasked_exercise_with_recovery.task_step.task.task_steps.count

      expect{
        api_put :recovery, user_2_token, parameters: {
          id: tasked_exercise_with_recovery.task_step.id
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
          id: tasked_exercise_with_recovery.task_step.id
        }
      }.to change{tasked_exercise_with_recovery.task_step.task
                                               .reload.task_steps.count}
      expect(response).to have_http_status(:success)

      hash = JSON.parse(response.body)
      expect(hash['refresh_step']['url']).to eq task_step.tasked.url

      recovery_step = tasked_exercise_with_recovery.task_step.next_by_number
      tasked = recovery_step.tasked

      expect(hash['recovery_step']).to eq JSON.parse(
        Api::V1::Tasks::TaskedExerciseRepresenter.new(tasked).to_json
      )

      expect(tasked.los & tasked_exercise_with_recovery.parser.los).not_to be_empty
      expect(recovery_step.task).to eq(task)
      expect(recovery_step.number).to(
        eq(tasked_exercise_with_recovery.task_step.number + 1)
      )
    end

    it "should not allow random user to refresh exercises" do
      step_count = tasked_exercise_with_recovery.task_step.task.task_steps.count

      expect{
        api_put :refresh, user_2_token, parameters: {
          id: tasked_exercise_with_recovery.task_step.id
        }
      }.to raise_error(SecurityTransgression)

      expect(tasked_exercise_with_recovery.task_step.task.reload.task_steps.count).to(
        eq step_count
      )
    end

    it "should not allow owner to refresh taskeds without recovery steps" do
      tasked = create_tasked(:tasked_reading, user_1_role)

      step_count = tasked_exercise.task_step.task.task_steps.count

      expect{
        api_put :refresh, user_1_token, parameters: {
          id: tasked_exercise.task_step.id
        }
      }.not_to change{tasked_exercise.task_step.task.reload.task_steps.count}
    end
  end

  describe "#completed" do
    it "should allow marking completion of reading steps by the owner" do
      tasked = create_tasked(:tasked_reading, user_1_role)
      api_put :completed, user_1_token, parameters: { id: tasked.task_step.id }

      expect(response).to have_http_status(:success)

      expect(response.body).to eq(Api::V1::Tasks::TaskedReadingRepresenter.new(
        tasked.reload
      ).to_json)

      expect(tasked.task_step(true).completed?).to be_truthy
    end

    it "should not allow marking completion of reading steps by random user" do
      tasked = create_tasked(:tasked_reading, user_1_role)
      expect{
        api_put :completed, user_2_token, parameters: { id: tasked.task_step.id }
      }.to raise_error SecurityTransgression
      expect(tasked.task_step(true).completed?).to be_falsy
    end

    it "should allow marking completion of exercise steps" do
      tasked = create_tasked(:tasked_exercise, user_1_role).reload
      api_put :completed, user_1_token, parameters: { id: tasked.task_step.id }

      expect(response).to have_http_status(:success)

      expect(response.body).to eq(
        Api::V1::Tasks::TaskedExerciseRepresenter.new(tasked.reload).to_json
      )

      expect(tasked.task_step(true).completed?).to be_truthy
    end
  end

  describe "practice task update step" do
    it "allows updating of a step (needed to test access to legacy and SS taskings)" do
      AddUserAsCourseStudent[course: course, user: user_1.entity_user]
      task = ResetPracticeWidget[role: Entity::Role.last, exercise_source: :fake]

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
    tasking = FactoryGirl.create(:tasks_tasking, role: owner,
                                 task: tasked.task_step.task.entity_task)
    tasked
  end

end
