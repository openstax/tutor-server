require 'rails_helper'

RSpec.describe Api::V1::PeriodsController, type: :controller, api: true, version: :v1 do
  let(:course) { CreateCourse[name: 'Biology I'] }
  let(:other_course) { CreateCourse[name: 'Other course'] }

  let(:teacher_user) { FactoryGirl.create(:user) }

  let(:teacher_token) { FactoryGirl.create(:doorkeeper_access_token,
                                           resource_owner_id: teacher_user.id) }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher_user]
  end

  describe '#create' do
    it 'allows teachers to create periods' do
      allow(Babbler).to receive(:babble) { 'awesome programmer' }

      api_post :create, teacher_token, parameters: { course_id: course.id,
                                                     period: { name: '7th Period' } }

      expect(response.body_as_hash).to eq({
        id: CourseMembership::Models::Period.last.id.to_s,
        name: '7th Period',
        enrollment_code: 'awesome programmer',
        default_open_time: '00:01',
        default_due_time: '07:00'
      })
    end

    it 'ensures the person is a teacher of the course' do
      rescuing_exceptions do
        api_post :create, teacher_token, parameters: { course_id: other_course.id,
                                                       period: { name: '7th Period' } }
      end

      expect(response).to have_http_status(403)
    end

    it "allows same name on periods if the previous one was deleted" do
      period = CreatePeriod[course: course, name: '8th Period']
      CourseMembership::DeletePeriod[period: period]

      api_post :create, teacher_token, parameters: { course_id: course.id,
                                                     period: { name: '8th Period' } }

      expect(response).to have_http_status(201)
      expect(response.body_as_hash[:name]).to eq('8th Period')
    end
  end

  describe '#update' do
    let(:period) { CreatePeriod[course: course, name: '8th Period'] }

    it 'allows teachers to rename periods' do
      api_patch :update, teacher_token, parameters: { id: period.id,
                                                      period: { name: 'Skip class!!!' } }

      expect(response.body_as_hash[:name]).to eq('Skip class!!!')
    end

    it 'allows teachers to change the enrollment code' do
      api_patch :update, teacher_token,
        parameters: { id: period.id, period: { enrollment_code: 'handsome programmer' } }

      expect(response).to have_http_status(200)
      expect(response.body_as_hash[:enrollment_code]).to eq('handsome programmer')
    end

    it 'ensures the person is a teacher of the course' do
      other_period = CreatePeriod[course: other_course]

      rescuing_exceptions do
        api_put :update, teacher_token, parameters: { id: other_period.id,
                                                      period: { name: '7th Period' } }
      end

      expect(response).to have_http_status(403)
    end

    it 'allows teachers to change the default open time' do
      api_patch :update, teacher_token,
        parameters: { id: period.id, period: { default_open_time: '18:32' } }

      expect(response).to have_http_status(200)
      expect(response.body_as_hash[:default_open_time]).to eq('18:32')
    end

    it 'freaks if the default open time is in a bad format' do
      expect {
        api_patch :update, teacher_token, parameters: { id: period.id, period: { default_open_time: '1:00' } }
      }.not_to change{ period.to_model.reload.default_open_time }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'allows teachers to change the default due time' do
      api_patch :update, teacher_token,
        parameters: { id: period.id, period: { default_due_time: '18:33' } }

      expect(response).to have_http_status(200)
      expect(response.body_as_hash[:default_due_time]).to eq('18:33')
    end

    it 'freaks if the default due time is in a bad format' do
      expect {
        api_patch :update, teacher_token, parameters: { id: period.id, period: { default_due_time: '25:00' } }
      }.not_to change{ period.to_model.reload.default_open_time }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe '#destroy' do
    it 'allows teachers to delete periods' do
      period = CreatePeriod[course: course, name: '8th Period']

      api_delete :destroy, teacher_token, parameters: { id: period.id }

      expect(response).to have_http_status(204)
      expect(response.body).to be_empty
      expect(CourseMembership::Models::Period.all).to be_empty
    end

    it 'will not delete periods with active enrollments' do
      period = CreatePeriod[course: course, name: '8th Period']
      student = FactoryGirl.create(:user)
      AddUserAsPeriodStudent[period: period, user: student]

      api_delete :destroy, teacher_token, parameters: { id: period.id }

      errors = response.body_as_hash[:errors][0]

      expect(response).to have_http_status(:unprocessable_entity)
      expect(errors[:data][:attribute]).to eq('students')
      expect(errors[:message]).to eq(
        'must be moved to another period before this period can be deleted'
      )
      expect(CourseMembership::Models::Period.all).not_to be_empty
    end

    it 'ensures the person is a teacher of the course' do
      other_period = CreatePeriod[course: other_course]

      rescuing_exceptions do
        api_delete :destroy, teacher_token, parameters: { id: other_period.id }
      end

      expect(response).to have_http_status(403)
      expect(CourseMembership::Models::Period.all).to include(other_period.to_model)
    end

    it "does not delete periods already deleted" do
      period = CreatePeriod[course: course, name: '8th Period']
      CourseMembership::DeletePeriod[period: period]

      rescuing_exceptions do
        api_delete :destroy, teacher_token, parameters: { id: period.id }
      end

      expect(response).to have_http_status(404)
    end
  end
end
