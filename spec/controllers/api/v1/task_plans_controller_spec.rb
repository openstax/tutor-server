require "rails_helper"

describe Api::V1::TaskPlansController, type: :controller, api: true, version: :v1 do

  let!(:course)    { CreateCourse[name: 'Anything'] }
  let!(:period)    { CreatePeriod[course: course] }

  let!(:user)      {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:teacher)   {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:student)   {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  let!(:page)      { FactoryGirl.create :content_page }
  let!(:task_plan) { FactoryGirl.build(:tasks_task_plan,
                                       owner: course,
                                       assistant: get_assistant(course: course,
                                                                task_plan_type: 'reading'),
                                       settings: { page_ids: [page.id.to_s] },
                                       type: 'reading',
                                       num_tasking_plans: 0) }
  let!(:tasking_plan) { FactoryGirl.create :tasks_tasking_plan,
                                           task_plan: task_plan,
                                           target: period.to_model,
                                           opens_at: Time.now + 1.day }

  let!(:published_task_plan) { FactoryGirl.create(:tasked_task_plan,
                                                  number_of_students: 0,
                                                  owner: course,
                                                  assistant: get_assistant(course: course,
                                                                           task_plan_type: 'reading'),
                                                  settings: { page_ids: [page.id.to_s] },
                                                  published_at: Time.now) }

  let!(:unaffiliated_teacher) {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  before do
    AddUserAsCourseTeacher.call(course: course, user: teacher)
    AddUserAsPeriodStudent.call(period: period, user: student)
  end

  context 'show' do
    before(:each) do
      task_plan.save!
    end

    it 'cannot be requested by unrelated teachers' do
      controller.sign_in unaffiliated_teacher
      expect {
        api_get :show, nil, parameters: {id: task_plan.id}
      }.to raise_error(SecurityTransgression)
    end

    it "can be requested by the course's teacher" do
      controller.sign_in teacher
      expect {
        api_get :show, nil, parameters: {id: task_plan.id}
      }.to_not raise_error
    end

    it "allows a teacher to view their course's task_plan" do
      controller.sign_in teacher
      api_get :show, nil, parameters: { course_id: course.id, id: task_plan.id }
      expect(response).to have_http_status(:success)

      # Ignore the stats for this test
      expect(response.body_as_hash.except(:stats).to_json).to(
        eq(Api::V1::TaskPlanRepresenter.new(task_plan).to_json)
      )
    end

    it 'does not allow an unauthorized user to view the task_plan' do
      controller.sign_in user
      expect { api_get :show, nil, parameters: {course_id: course.id, id: task_plan.id} }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to view the task_plan' do
      expect {
        api_get :show, nil, parameters: {course_id: course.id, id: task_plan.id}
      }.to raise_error(SecurityTransgression)
    end

    it 'does not include stats' do
      controller.sign_in teacher
      api_get :show, nil, parameters: {id: task_plan.id}
      body = JSON.parse(response.body)
      expect(body['stats']).to be_nil
    end
  end

  context 'create' do
    it 'allows a teacher to create a task_plan for their course' do
      controller.sign_in teacher
      expect { api_post :create,
                        nil,
                        parameters: { course_id: course.id },
                        raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan).to_json }
        .to change{ Tasks::Models::TaskPlan.count }.by(1)
      expect(response).to have_http_status(:success)

      task_plan = Tasks::Models::TaskPlan.last
      course = task_plan.owner
      Time.use_zone(course.profile.timezone) do
        expect(response.body).to(
          eq(Api::V1::TaskPlanRepresenter.new(Tasks::Models::TaskPlan.last).to_json)
        )
      end
    end

    it 'does not allow an unauthorized user to create a task_plan' do
      controller.sign_in user
      expect {
        api_post :create,
                 nil,
                 parameters: { course_id: course.id },
                 raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan).to_json
      }.to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to create a task_plan' do
      expect {
        api_post :create,
                 nil,
                 parameters: { course_id: course.id },
                 raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan).to_json
      }.to raise_error(SecurityTransgression)
    end

    it 'fails if no Assistant found' do
      allow(request).to receive(:remote_ip) { '96.21.0.39' }

      controller.sign_in teacher
      result = nil

      expect {
        result = api_post :create,
                          nil,
                          parameters: { course_id: course.id },
                          raw_post_data: Api::V1::TaskPlanRepresenter
                                           .new(task_plan).to_hash
                                           .except('type').to_json
      }.to raise_error(IllegalState).and change{ Tasks::Models::TaskPlan.count }.by 0
    end

    context 'when is_publish_requested is set' do
      let!(:valid_json_hash) {
        task_plan.is_publish_requested = true
        JSON.parse(Api::V1::TaskPlanRepresenter.new(task_plan).to_json)
      }

      it 'allows a teacher to publish a task_plan for their course' do
        controller.sign_in teacher
        expect { api_post :create,
                          nil,
                          parameters: { course_id: course.id },
                          raw_post_data: valid_json_hash.to_json }
          .to change{ Tasks::Models::TaskPlan.count }.by(1)
        expect(response).to have_http_status(:success)
        new_task_plan = Tasks::Models::TaskPlan.find(JSON.parse(response.body)['id'])
        expect(new_task_plan.published_at).to be_within(3.seconds).of(Time.now)
        expect(new_task_plan.publish_last_requested_at).to be_within(10.seconds).of(Time.now)

        # Revert task_plan to its state when the job was queued
        new_task_plan.is_publish_requested = true
        new_task_plan.published_at = nil
        expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(new_task_plan).to_json

        response_hash = JSON.parse(response.body)
        expect(response_hash['publish_job_url']).to include("/api/jobs/")
      end

      it 'returns an error message if the task_plan settings are invalid' do
        invalid_json_hash = valid_json_hash
        invalid_json_hash['settings']['exercise_ids'] = [1, 2, 3]
        invalid_json_hash['settings']['exercises_count_dynamic'] = 3

        controller.sign_in teacher
        expect { api_post :create,
                          nil,
                          parameters: { course_id: course.id },
                          raw_post_data: invalid_json_hash.to_json }
          .not_to change{ Tasks::Models::TaskPlan.count }
        expect(response).to have_http_status(:unprocessable_entity)
        error = response.body_as_hash[:errors].first
        expect(error[:message]).to include "Settings - The property '#/' contains additional properties [\"exercise_ids\", \"exercises_count_dynamic\"] outside of the schema when none are allowed in schema"
      end
    end
  end

  context 'update' do
    before(:each) do
      task_plan.save!
    end

    it 'allows a teacher to update a task_plan for their course' do
      controller.sign_in teacher
      api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
              raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan).to_json
      expect(response).to have_http_status(:success)
      task_plan.reload ## task_plan can be altered on the way in to/out of the database
      course = task_plan.owner
      Time.use_zone(course.profile.timezone) do
        expect(response.body).to(
          eq(Api::V1::TaskPlanRepresenter.new(task_plan).to_json)
        )
      end
    end

    it 'does not allow an unauthorized user to update a task_plan' do
      controller.sign_in user
      expect { api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
               raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan).to_json }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to update a task_plan' do
      expect { api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
               raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan).to_json }
        .to raise_error(SecurityTransgression)
    end

    context 'when is_publish_requested is set' do
      let!(:valid_json_hash) {
        task_plan.is_publish_requested = true
        JSON.parse(Api::V1::TaskPlanRepresenter.new(task_plan).to_json)
      }

      it 'allows a teacher to publish a task_plan for their course' do
        controller.sign_in teacher
        api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                              raw_post_data: valid_json_hash.to_json
        expect(response).to have_http_status(:accepted)
        # Need to reload the task_plan since publishing it will set the
        # publication dates and change the representation
        expect(task_plan.reload.publish_last_requested_at).to be_within(10.seconds).of(Time.now)
        expect(task_plan.published_at).to be_within(1.second).of(Time.now)

        # Revert task_plan to its state when the job was queued
        task_plan.published_at = nil
        expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(task_plan).to_json

        response_hash = JSON.parse(response.body)
        expect(response_hash['publish_job_url']).to include("/api/jobs/")

        task_plan.reload

        publish_last_requested_at = task_plan.publish_last_requested_at
        published_at = task_plan.published_at
        publish_job_uuid = task_plan.publish_job_uuid

        valid_json_hash['tasking_plans'].first['opens_at'] = Time.zone.now.yesterday

        api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                              raw_post_data: valid_json_hash.to_json
        expect(response).to have_http_status(:accepted)
        # Need to reload the task_plan since publishing it will set the
        # publication dates and change the representation
        expect(task_plan.reload.publish_last_requested_at).not_to eq publish_last_requested_at
        expect(task_plan.published_at).to eq published_at
        expect(task_plan.publish_job_uuid).not_to eq publish_job_uuid

        # Revert task_plan to its state when the job was queued
        task_plan.published_at = published_at
        expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(task_plan).to_json

        response_hash = JSON.parse(response.body)
        expect(response_hash['publish_job_url']).to include("/api/jobs/")

        task_plan.reload

        publish_last_requested_at = task_plan.publish_last_requested_at
        published_at = task_plan.published_at
        publish_job_uuid = task_plan.publish_job_uuid

        valid_json_hash['title'] = 'Canceled'

        # Since the task_plan opens_at is now in the past,
        # further publish requests should be ignored
        expect {
          api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                                raw_post_data: valid_json_hash.to_json
        }.not_to change{ task_plan.reload.tasks }
        expect(response).to have_http_status(:ok)

        expect(task_plan.publish_last_requested_at).to eq publish_last_requested_at
        expect(task_plan.published_at).to eq published_at
        expect(task_plan.publish_job_uuid).to eq publish_job_uuid
        expect(task_plan.title).to eq 'Canceled'

        expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(task_plan).to_json
      end

      it 'returns an error message if the task_plan settings are invalid' do
        invalid_json_hash = valid_json_hash
        invalid_json_hash['settings']['exercise_ids'] = [1, 2, 3]
        invalid_json_hash['settings']['exercises_count_dynamic'] = 3

        controller.sign_in teacher
        api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                              raw_post_data: invalid_json_hash.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        error = response.body_as_hash[:errors].first
        expect(error[:message]).to include "Settings - The property '#/' contains additional properties [\"exercise_ids\", \"exercises_count_dynamic\"] outside of the schema when none are allowed in schema"
      end
    end
  end

  context 'destroy' do
    before(:each) do
      task_plan.save!
    end

    it 'allows a teacher to destroy a task_plan for their course' do
      controller.sign_in teacher
      expect{ api_delete :destroy, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .to change{ Tasks::Models::TaskPlan.count }.by(-1)
      expect(response).to have_http_status(:success)
      expect(response.body).to be_blank
    end

    it 'does not allow an unauthorized user to destroy a task_plan' do
      controller.sign_in user
      expect { api_delete :destroy, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to destroy a task_plan' do
      expect { api_delete :destroy, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .to raise_error(SecurityTransgression)
    end

    it 'does not leave orphaned entity_tasks behind' do
      # Change the opens_at dates for the tasks so we can delete them
      published_task_plan.tasks.each do |task|
        task.opens_at = Time.now + 1.day
        task.save!
      end

      controller.sign_in teacher
      expect{ api_delete :destroy, nil, parameters: { course_id: course.id,
                                                      id: published_task_plan.id } }
        .to change{ ::Entity::Task.count }.by(-1)
      ::Entity::Task.all.each{ |entity_task| expect(entity_task.task).not_to be_nil }
    end
  end

  context 'stats' do

    it 'cannot be requested by unrelated teachers' do
      controller.sign_in unaffiliated_teacher
      expect {
        api_get :stats, nil, parameters: { id: published_task_plan.id }
      }.to raise_error(SecurityTransgression)
    end

    it "can be requested by the course's teacher" do
      controller.sign_in teacher
      expect {
        api_get :stats, nil, parameters: { id: published_task_plan.id }
      }.to_not raise_error
    end

    it 'includes stats' do
      controller.sign_in teacher
      api_get :stats, nil, parameters: { id: published_task_plan.id }
      body = JSON.parse(response.body)
      # The representer spec does validate the json so we'll rely on it and just check presense
      expect(body['stats']).to be_a(Array)
    end

  end

  context 'review' do

    it 'cannot be requested by unrelated teachers' do
      controller.sign_in unaffiliated_teacher
      expect {
        api_get :review, nil, parameters: { id: published_task_plan.id }
      }.to raise_error(SecurityTransgression)
    end

    it "can be requested by the course's teacher" do
      controller.sign_in teacher
      expect {
        api_get :review, nil, parameters: { id: published_task_plan.id }
      }.to_not raise_error
    end

    it 'includes stats' do
      controller.sign_in teacher
      api_get :review, nil, parameters: { id: published_task_plan.id }
      body = JSON.parse(response.body)
      # The representer spec does validate the json so we'll rely on it and just check presense
      expect(body['stats']).to be_a(Array)
    end

  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end

end
