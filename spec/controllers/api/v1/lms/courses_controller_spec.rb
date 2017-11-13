require 'rails_helper'

RSpec.describe Api::V1::Lms::CoursesController, type: :controller, api: true, version: :v1 do
  let(:course)  { FactoryBot.create :course_profile_course }
  let!(:lms_app) { FactoryBot.create(:lms_app, owner: course) }
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { FactoryBot.create(:doorkeeper_access_token,
                                           resource_owner_id: user.id) }

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


end
