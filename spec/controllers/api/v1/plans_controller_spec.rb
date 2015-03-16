require "rails_helper"

describe Api::V1::PlansController, :type => :controller, :api => true, :version => :v1 do

  let(:unaffiliated_teacher) {
    FactoryGirl.create :user
  }
  let(:teacher)        {
    u = FactoryGirl.create :user
    Domain::AddUserAsCourseTeacher.call(course: course, user: u)
    u
  }

  let(:course)      { Domain::CreateCourse.call.outputs.course }
  let(:assistant)   { FactoryGirl.create :assistant,
                         code_class_name: "IReadingAssistant" }
  let(:page) { FactoryGirl.create :content_page }

  let(:task_plan) {
    FactoryGirl.create( :task_plan, owner: course, assistant: assistant,
                        settings: { page_ids: [page.id] } )
  }


  context 'stats' do

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

    it 'includes stats with task_plan' do
      controller.sign_in teacher
      api_get :show, nil, parameters: {id: task_plan.id}
      body = JSON.parse(response.body)
      # Since the stats currently use dummy data it's difficult to check their values.
      # The representer spec does validate the json so we'll rely on it and just check presense
      expect(body['stats']).to be_a(Hash)
    end


  end
end
