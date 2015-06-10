require "rails_helper"

describe Api::V1::TaskPlansController, :type => :controller, :api => true, :version => :v1 do

  let!(:course) { CreateCourse.call.outputs.course }
  let!(:period) { CreatePeriod[course: course] }

  let!(:assistant) { FactoryGirl.create(
    :tasks_assistant, code_class_name: "Tasks::Assistants::IReadingAssistant"
  ) }

  let!(:course_assistant) { FactoryGirl.create :tasks_course_assistant,
                                               course: course,
                                               assistant: assistant,
                                               tasks_task_plan_type: 'test' }

  let!(:user) { FactoryGirl.create :user_profile }
  let!(:teacher) { FactoryGirl.create :user_profile }
  let!(:student) { FactoryGirl.create :user_profile }

  let!(:page) { FactoryGirl.create :content_page }
  let!(:task_plan) { FactoryGirl.create(:tasks_task_plan,
                                        owner: course,
                                        assistant: assistant,
                                        settings: { page_ids: [page.id.to_s] },
                                        type: 'test') }
  let!(:tasking_plan) {
    tp = FactoryGirl.build :tasks_tasking_plan, task_plan: task_plan, target: period.to_model
    task_plan.tasking_plans << tp
    tp
  }

  let!(:published_task_plan) { FactoryGirl.create(:tasked_task_plan,
                                                  number_of_students: 1,
                                                  owner: course,
                                                  assistant: assistant,
                                                  settings: { page_ids: [page.id.to_s] },
                                                  published_at: Time.now) }

  let(:unaffiliated_teacher) { FactoryGirl.create :user_profile }

  before do
    AddUserAsCourseTeacher.call(course: course, user: teacher.entity_user)
    AddUserAsPeriodStudent.call(period: period, user: student.entity_user)
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

    it 'fails with 422 Unprocessable Entity if no Assistant found' do
      controller.sign_in teacher
      result = nil
      expect {
        result = api_post :create,
                          nil,
                          parameters: { course_id: course.id },
                          raw_post_data: Api::V1::TaskPlanRepresenter
                                           .new(task_plan).to_hash
                                           .except('type').to_json
      }.not_to change{ Tasks::Models::TaskPlan.count }
      expect(response).to have_http_status(:unprocessable_entity)
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
  end

  context 'publish' do
    before(:each) do
      task_plan.save!
    end

    it 'allows a teacher to publish a task_plan for their course' do
      controller.sign_in teacher

      expect {
        api_post :publish, nil, parameters: { course_id: course.id, id: task_plan.id }
      }.to change{ Tasks::Models::Task.count }.by(1)

      expect(response).to have_http_status(:accepted)

      job_hash = JSON.parse(response.body)

      expect(job_hash['task_plan']).to eq("/api/plans/#{task_plan.id}")
    end

    it 'does not allow an unauthorized user to publish a task_plan' do
      controller.sign_in user
      expect {
        api_post :publish, nil, parameters: { course_id: course.id, id: task_plan.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to publish a task_plan' do
      expect {
        api_post :publish, nil, parameters: { course_id: course.id, id: task_plan.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'returns an error message if the task_plan settings are invalid' do
      task_plan.settings[:exercise_ids] = [1, 2, 3]
      task_plan.settings[:exercises_count_dynamic] = 3
      task_plan.save!

      controller.sign_in teacher
      expect {
        api_post :publish, nil, parameters: { course_id: course.id, id: task_plan.id }
      }.not_to change{ Tasks::Models::Task.count }
      expect(response).to have_http_status(:unprocessable_entity)
      error = response.body_as_hash
      expect(error[:code]).to eq 'invalid_settings'
      expect(error[:message]).to eq 'Invalid settings'
      expect(error[:data].first).to include("The property '#/' contains additional properties [\"exercise_ids\", \"exercises_count_dynamic\"] outside of the schema when none are allowed in schema")
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
      expect(body['stats']).to be_a(Hash)
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
      expect(body['stats']).to be_a(Hash)
    end

  end

end
