require 'rails_helper'

RSpec.describe Api::V1::Lms::CoursesController, type: :controller, api: true, version: :v1 do
  let(:course)  { FactoryBot.create :course_profile_course }
  let!(:lms_app) { FactoryBot.create(:lms_app, owner: course) }
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { FactoryBot.create(:doorkeeper_access_token,
                                           resource_owner_id: user.id) }

  let(:app) { Lms::WilloLabs.new }
  let(:launch_request) { FactoryBot.create(:launch_request, app: app) }
  let(:lms_launch_id) { Lms::Launch.from_request(launch_request).persist! }
  let(:lms_launch) { Lms::Launch.from_id(lms_launch_id) }

  it 'allows teachers to retrieve secrets' do
    AddUserAsCourseTeacher[course: course, user: user]

    api_get :show, token, parameters: { id: course.id }
    expect(response).to have_http_status(:ok)

    expect(
      response.body_as_hash
    ).to match(
           a_hash_including(
             key: lms_app.key,
             secret: lms_app.secret
           )
         )

  end

  it 'rejects non-teachers' do
    expect {
      api_get :show, token, parameters: { id: course.id }
    }.to raise_error(SecurityTransgression)
  end

  it 'pairs a course to lms' do
    AddUserAsCourseTeacher[course: course, user: user]
    expect_any_instance_of(
      ::IMS::LTI::Services::MessageAuthenticator
    ).to receive(:valid_signature?).and_return(true)
    lms_launch.attempt_context_creation
    response = api_get :pair, token, parameters: { id: course.id }, session: { launch_id: lms_launch_id }
    expect(JSON.parse(response.body)['success']).to eq true
    expect(lms_launch.context.reload.course).to eq course
    expect(course.reload.is_lms_enabled).to be true
  end

end
