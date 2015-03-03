require "rails_helper"

describe Api::V1::TaskPlansController, :type => :controller,
                                       :api => true,
                                       :version => :v1 do

  let!(:course)      { Domain::CreateCourse.call.outputs.course }
  let!(:assistant)   { FactoryGirl.create :assistant,
                         code_class_name: "IReadingAssistant" }
  let!(:legacy_user) { FactoryGirl.create :user }
  let!(:user)        {
    LegacyUser::FindOrCreateUserForLegacyUser.call(legacy_user).outputs.user
  }
  let!(:legacy_teacher) { FactoryGirl.create :user }
  let!(:teacher)        {
    u = LegacyUser::FindOrCreateUserForLegacyUser.call(legacy_teacher)
                                                 .outputs.user
    Domain::AddUserAsCourseTeacher.call(course: course, user: u)
    u
  }

  let!(:page) { FactoryGirl.create :content_page }
  let!(:task_plan)    { FactoryGirl.build :task_plan,
                                          owner: course,
                                          assistant: assistant,
                                          settings: { page_ids: [page.id] } }
  let!(:tasking_plan) {
    tp = FactoryGirl.build :tasking_plan, task_plan: task_plan, target: user
    task_plan.tasking_plans << tp
    tp
  }

  context 'show' do
    before(:each) do
      task_plan.save!
    end

    it 'allows a teacher to view their course\'s task_plan' do
      controller.sign_in legacy_teacher
      api_get :show, nil, parameters: {course_id: course.id,
                                       id: task_plan.id}
      expect(response).to have_http_status(:success)

      expect(response.body).to(
        eq(Api::V1::TaskPlanRepresenter.new(task_plan).to_json))
    end

    it 'does not allow an unauthorized user to view the task_plan' do
      controller.sign_in legacy_user
      expect { api_get :show, nil, parameters: {course_id: course.id,
                                                id: task_plan.id} }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to view the task_plan' do
      expect {
        api_get :show, nil, parameters: {course_id: course.id,
                                         id:        task_plan.id}
      }.to raise_error(SecurityTransgression)
    end
  end

  context 'create' do
    it 'allows a teacher to create a task_plan for their course' do
      controller.sign_in legacy_teacher
      expect { api_post :create, nil, parameters: {course_id: course.id},
                        raw_post_data: Api::V1::TaskPlanRepresenter
                                         .new(task_plan).to_json }
        .to change{ TaskPlan.count }.by(1)
      expect(response).to have_http_status(:success)

      expect(response.body).to(
        eq(Api::V1::TaskPlanRepresenter.new(TaskPlan.last).to_json))
    end

    it 'does not allow an unauthorized user to create a task_plan' do
      controller.sign_in legacy_user
      expect { api_post :create, nil, parameters: {course_id: course.id},
               raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan)
                                                          .to_json }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to create a task_plan' do
      expect { api_post :create, nil, parameters: {course_id: course.id},
               raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan)
                                                          .to_json }
        .to raise_error(SecurityTransgression)
    end
  end

  context 'update' do
    before(:each) do
      task_plan.save!
    end

    it 'allows a teacher to update a task_plan for their course' do
      controller.sign_in legacy_teacher
      api_put :update, nil, parameters: {course_id: course.id,
                                         id: task_plan.id},
              raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan)
                                                         .to_json
      expect(response).to have_http_status(:success)
      expect(response.body).to be_blank
    end

    it 'does not allow an unauthorized user to update a task_plan' do
      controller.sign_in legacy_user
      expect { api_put :update, nil, parameters: {course_id: course.id,
                                                  id: task_plan.id},
               raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan)
                                                          .to_json }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to update a task_plan' do
      expect { api_put :update, nil, parameters: {course_id: course.id,
                                                  id: task_plan.id},
               raw_post_data: Api::V1::TaskPlanRepresenter.new(task_plan)
                                                          .to_json }
        .to raise_error(SecurityTransgression)
    end
  end

  context 'publish' do
    before(:each) do
      task_plan.save!
    end

    it 'allows a teacher to publish a task_plan for their course' do
      controller.sign_in legacy_teacher
      expect { api_post :publish, nil, parameters: {course_id: course.id,
                                                    id: task_plan.id} }
        .to change{ Task.count }.by(1)
      expect(response).to have_http_status(:success)
      expect(response.body).to(
        eq(Api::V1::TaskPlanRepresenter.new(task_plan).to_json))
    end

    it 'does not allow an unauthorized user to publish a task_plan' do
      controller.sign_in legacy_user
      expect { api_post :publish, nil, parameters: {course_id: course.id,
                                                    id: task_plan.id} }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to publish a task_plan' do
      expect { api_post :publish, nil, parameters: {course_id: course.id,
                                                    id: task_plan.id} }
        .to raise_error(SecurityTransgression)
    end
  end

  context 'destroy' do
    before(:each) do
      task_plan.save!
    end

    it 'allows a teacher to destroy a task_plan for their course' do
      controller.sign_in legacy_teacher
      expect{ api_delete :destroy, nil, parameters: {course_id: course.id,
                                                     id: task_plan.id} }
        .to change{ TaskPlan.count }.by(-1)
      expect(response).to have_http_status(:success)
      expect(response.body).to be_blank
    end

    it 'does not allow an unauthorized user to destroy a task_plan' do
      controller.sign_in legacy_user
      expect { api_delete :destroy, nil, parameters: {course_id: course.id,
                                                      id: task_plan.id} }
        .to raise_error(SecurityTransgression)
    end

    it 'does not allow an anonymous user to destroy a task_plan' do
      expect { api_delete :destroy, nil, parameters: {course_id: course.id,
                                                      id: task_plan.id} }
        .to raise_error(SecurityTransgression)
    end
  end

end
