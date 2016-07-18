require "rails_helper"

describe Api::V1::TaskPlansController, type: :controller, api: true, version: :v1 do

  let(:course)    { CreateCourse[name: 'Anything'] }
  let(:period)    { CreatePeriod[course: course] }

  let(:user)      { FactoryGirl.create(:user) }
  let(:teacher)   { FactoryGirl.create(:user) }
  let(:student)   { FactoryGirl.create(:user) }

  let!(:published_task_plan) { FactoryGirl.create(:tasked_task_plan,
                                                  number_of_students: 0,
                                                  owner: course,
                                                  assistant: get_assistant(
                                                    course: course, task_plan_type: 'reading'),
                                                  published_at: Time.current) }
  let(:ecosystem)  { published_task_plan.ecosystem }
  let(:page)       { ecosystem.pages.first }

  let(:task_plan)  { FactoryGirl.build(:tasks_task_plan,
                                       owner: course,
                                       assistant: get_assistant(
                                         course: course, task_plan_type: 'reading'
                                       ),
                                       content_ecosystem_id: ecosystem.id,
                                       settings: { page_ids: [page.id.to_s] },
                                       type: 'reading',
                                       num_tasking_plans: 0) }

  let!(:tasking_plan) { FactoryGirl.create :tasks_tasking_plan,
                                           task_plan: task_plan,
                                           target: period.to_model,
                                           opens_at: Time.current.tomorrow }

  let(:unaffiliated_teacher) { FactoryGirl.create(:user) }

  before do
    course.time_zone.update_attribute(:name, 'Pacific Time (US & Canada)')
    AddUserAsCourseTeacher.call(course: course, user: teacher)
    AddUserAsPeriodStudent.call(period: period, user: student)
  end

  context '#show' do
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
        eq(Api::V1::TaskPlanRepresenter.new(task_plan.reload).to_json)
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

  context '#create' do
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
      expect(response.body).to(
        eq(Api::V1::TaskPlanRepresenter.new(Tasks::Models::TaskPlan.last).to_json)
      )
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
      let(:valid_json_hash) do
        Api::V1::TaskPlanRepresenter.new(task_plan).to_hash.merge('is_publish_requested' => true)
      end

      it 'allows a teacher to publish a task_plan for their course' do
        controller.sign_in teacher
        start_time = Time.current
        expect { api_post :create,
                          nil,
                          parameters: { course_id: course.id },
                          raw_post_data: valid_json_hash.to_json }
          .to change{ Tasks::Models::TaskPlan.count }.by(1)
        end_time = Time.current
        expect(response).to have_http_status(:success)
        new_task_plan = Tasks::Models::TaskPlan.find(JSON.parse(response.body)['id'])
        expect(new_task_plan.publish_last_requested_at).to be > start_time
        expect(new_task_plan.first_published_at).to be > new_task_plan.publish_last_requested_at
        expect(new_task_plan.first_published_at).to be < end_time
        expect(new_task_plan.last_published_at).to eq new_task_plan.first_published_at

        # Revert task_plan to its state when the job was queued
        new_task_plan.is_publish_requested = true
        new_task_plan.first_published_at = nil
        new_task_plan.last_published_at = nil
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

  context '#update' do
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
      expect(response.body).to(
        eq(Api::V1::TaskPlanRepresenter.new(task_plan).to_json)
      )
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
      let(:valid_json_hash) do
        Api::V1::TaskPlanRepresenter.new(task_plan).to_hash.merge('is_publish_requested' => true)
      end

      it 'allows a teacher to publish a task_plan for their course' do
        controller.sign_in teacher
        start_time = Time.current
        api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                              raw_post_data: valid_json_hash.to_json
        end_time = Time.current
        expect(response).to have_http_status(:accepted)
        # Need to reload the task_plan since publishing it will set the
        # publication dates and change the representation
        task_plan.reload
        expect(task_plan.publish_last_requested_at).to be > start_time
        expect(task_plan.first_published_at).to be > task_plan.publish_last_requested_at
        expect(task_plan.first_published_at).to be < end_time
        expect(task_plan.last_published_at).to eq task_plan.first_published_at

        # Revert task_plan to its state when the job was queued
        task_plan.first_published_at = nil
        task_plan.last_published_at = nil
        expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(task_plan).to_json

        response_hash = JSON.parse(response.body)
        expect(response_hash['publish_job_url']).to include("/api/jobs/")
      end

      it 'does not update first_published_at for task_plans that are already published' do
        controller.sign_in teacher

        time_zone = task_plan.tasking_plans.first.time_zone.to_tz

        publish_last_requested_at = Time.current
        published_at = Time.current
        publish_job_uuid = SecureRandom.uuid

        task_plan.publish_last_requested_at = publish_last_requested_at
        task_plan.first_published_at = published_at
        task_plan.last_published_at = published_at
        task_plan.publish_job_uuid = publish_job_uuid
        task_plan.save!

        sleep(1)

        new_opens_at = time_zone.now.yesterday
        valid_json_hash['tasking_plans'].first['opens_at'] = new_opens_at

        api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                              raw_post_data: valid_json_hash.to_json

        expect(response).to have_http_status(:accepted)
        # Need to reload the task_plan since publishing it will set
        # publish_last_requested_at and change the representation
        expect(task_plan.reload.publish_last_requested_at).not_to(
          be_within(1).of(publish_last_requested_at)
        )
        expect(task_plan.first_published_at).to be_within(1).of(published_at)
        expect(task_plan.last_published_at).not_to be_within(1).of(published_at)
        expect(task_plan.publish_job_uuid).not_to eq publish_job_uuid

        task_plan.tasks.each do |task|
          expect(task.opens_at).to be_within(1).of(new_opens_at)
        end

        # Revert task_plan to its state when the job was queued
        task_plan.first_published_at = published_at
        task_plan.last_published_at = published_at
        expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(task_plan).to_json

        response_hash = JSON.parse(response.body)
        expect(response_hash['publish_job_url']).to include("/api/jobs/")
      end

      it 'does not republish the task_plan or allow the open date
          to be changed after the assignment is open' do
        controller.sign_in teacher

        time_zone = task_plan.tasking_plans.first.time_zone.to_tz

        opens_at = time_zone.now

        publish_last_requested_at = Time.current

        task_plan.update_attribute :publish_last_requested_at, publish_last_requested_at
        task_plan.tasking_plans.first.update_attribute :opens_at, opens_at

        DistributeTasks[task_plan]

        published_at = task_plan.reload.last_published_at
        publish_job_uuid = task_plan.publish_job_uuid

        valid_json_hash['title'] = 'Canceled'
        valid_json_hash['description'] = 'Canceled Assignment'

        new_opens_at = time_zone.now.tomorrow.beginning_of_minute
        new_due_at = new_opens_at + 1.week

        valid_json_hash['tasking_plans'].first['opens_at'] = new_opens_at
        valid_json_hash['tasking_plans'].first['due_at'] = new_due_at

        # Since the task_plan opens_at is now in the past,
        # further publish requests should be ignored
        expect {
          api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                                raw_post_data: valid_json_hash.to_json
        }.not_to change{ task_plan.reload.tasks }
        expect(response).to have_http_status(:ok)

        expect(task_plan.reload.publish_last_requested_at).to(
          be_within(1).of(publish_last_requested_at)
        )
        expect(task_plan.last_published_at).to be_within(1).of(published_at)
        expect(task_plan.publish_job_uuid).to eq publish_job_uuid
        expect(task_plan.title).to eq 'Canceled'
        expect(task_plan.description).to eq 'Canceled Assignment'
        task_plan.tasking_plans.each do |tp|
          expect(tp.opens_at).to be_within(1).of(opens_at)
          expect(tp.due_at).to be_within(1).of(new_due_at)
        end
        task_plan.tasks.each do |task|
          expect(task.opens_at).to be_within(1).of(opens_at)
          expect(task.due_at).to be_within(1).of(new_due_at)
        end

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

      it 'returns an error message if the tasking_plans are invalid' do
        invalid_json_hash = valid_json_hash
        invalid_json_hash['tasking_plans'] = [{ target_id: nil, target_type: 'not valid' }]

        controller.sign_in teacher
        api_put :update, nil, parameters: { course_id: course.id, id: task_plan.id },
                              raw_post_data: invalid_json_hash.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        error = response.body_as_hash[:errors].first
        expect(error[:message]).to include "Tasking plans is invalid"
      end
    end
  end

  context '#destroy' do
    before(:each) { task_plan.save! }

    it 'allows a teacher to destroy a task_plan for their course' do
      controller.sign_in teacher
      expect{ api_delete :destroy, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .to change{ Tasks::Models::TaskPlan.count }.by(-1)
      expect(response).to have_http_status(:success)
      expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(task_plan.reload).to_json
    end

    it 'does not allow a teacher to destroy a task_plan that is already destroyed' do
      task_plan.destroy!
      controller.sign_in teacher
      expect{ api_delete :destroy, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .not_to change{ Tasks::Models::TaskPlan.count }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq('task_plan_is_already_deleted')
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
  end

  context '#restore' do
    before(:each) do
      task_plan.save!
      task_plan.destroy!
    end

    it 'allows a teacher to restore a destroyed task_plan for their course' do
      controller.sign_in teacher
      expect{ api_put :restore, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .to change{ Tasks::Models::TaskPlan.count }.by(1)
      expect(response).to have_http_status(:success)
      expect(response.body).to eq Api::V1::TaskPlanRepresenter.new(task_plan.reload).to_json
    end

    it 'does not allow a teacher to restore a task_plan that is not destroyed' do
      task_plan.restore!(recursive: true)
      controller.sign_in teacher
      expect{ api_put :restore, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .not_to change{ Tasks::Models::TaskPlan.count }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq('task_plan_is_not_deleted')
    end

    it 'does not allow an unauthorized user to restore a task_plan' do
      controller.sign_in user
      expect { api_put :restore, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to restore a task_plan' do
      expect { api_put :restore, nil, parameters: { course_id: course.id, id: task_plan.id } }
        .to raise_error(SecurityTransgression)
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
