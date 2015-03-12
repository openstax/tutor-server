require "rails_helper"

describe Api::V1::PlansController, :type => :controller, :api => true, :version => :v1 do

  let(:legacy_teacher) { FactoryGirl.create :user }
  let(:teacher)        {
    u = LegacyUser::FindOrCreateUserForLegacyUser.call(legacy_teacher)
                                                 .outputs.user
    Domain::AddUserAsCourseTeacher.call(course: course, user: u)
    u
  }

  let(:course)      { Domain::CreateCourse.call.outputs.course }
  let(:assistant)   { FactoryGirl.create :assistant,
                         code_class_name: "IReadingAssistant" }
  let(:page) { FactoryGirl.create :content_page }

  let(:task_plan)    { FactoryGirl.create :task_plan,
      owner: course,
      assistant: assistant,
      settings: { page_ids: [page.id] } }


  context 'show' do
    it 'includes stats with task_plan' do
      controller.sign_in legacy_teacher
      api_get :show, nil, parameters: {id: task_plan.id}
      body = JSON.parse(response.body)
      # Since the stats currently use dummy data it's difficult to check their values.
      # The representer spec does validate the json so we'll rely on it and just check presense
      expect(body['stats']).to be_a(Hash)
    end

  end
end
