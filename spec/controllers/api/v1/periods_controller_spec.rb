require 'rails_helper'

RSpec.describe Api::V1::PeriodsController, type: :controller, api: true, version: :v1 do
  let(:course) { CreateCourse[name: 'Biology I'] }
  let(:other_course) { CreateCourse[name: 'Other course'] }

  let(:teacher_user) { FactoryGirl.create(:user) }

  let(:teacher_token) { FactoryGirl.create(:doorkeeper_access_token,
                                           resource_owner_id: teacher_user.id) }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher_user]
    allow(Babbler).to receive(:babble) { 'awesome programmer' }
  end

  describe '#create' do
    it 'allows teachers to create periods' do
      api_post :create, teacher_token, parameters: { course_id: course.id,
                                                     period: { name: '7th Period' } }

      expect(response.body_as_hash).to eq({
        id: CourseMembership::Models::Period.last.id.to_s,
        name: '7th Period',
        enrollment_code: 'awesome programmer'
      })
    end

    it 'ensures the person is a teacher of the course' do
      rescuing_exceptions do
        api_post :create, teacher_token, parameters: { course_id: other_course.id,
                                                       period: { name: '7th Period' } }
      end

      expect(response).to have_http_status(403)
    end
  end

  describe '#update' do
    it 'allows teachers to rename periods' do
      period = CreatePeriod[course: course, name: '8th Period']

      api_patch :update, teacher_token, parameters: { id: period.id,
                                                      period: { name: 'Skip class!!!' } }

      expect(response.body_as_hash[:name]).to eq('Skip class!!!')
    end

    it 'ensures the person is a teacher of the course' do
      other_period = CreatePeriod[course: other_course]

      rescuing_exceptions do
        api_put :update, teacher_token, parameters: { id: other_period.id,
                                                      period: { name: '7th Period' } }
      end

      expect(response).to have_http_status(403)
    end
  end
end
