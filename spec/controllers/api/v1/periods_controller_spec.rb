require 'rails_helper'

RSpec.describe Api::V1::PeriodsController, type: :controller, api: true, version: :v1 do
  let(:course)        { FactoryGirl.create :entity_course }
  let(:other_course)  { FactoryGirl.create :entity_course }

  let(:teacher_user)  { FactoryGirl.create(:user) }

  let(:teacher_token) { FactoryGirl.create(:doorkeeper_access_token,
                                           resource_owner_id: teacher_user.id) }

  before { AddUserAsCourseTeacher[course: course, user: teacher_user] }

  describe '#create' do
    it 'allows teachers to create periods' do
      allow(SecureRandom).to receive(:random_number) { 12345 }

      api_post :create, teacher_token, parameters: { course_id: course.id },
                                       raw_post_data: { name: '7th Period' }.to_json

      expect(response).to have_http_status(:created)
      expect(response.body_as_hash).to match({
        id: CourseMembership::Models::Period.last.id.to_s,
        name: '7th Period',
        enrollment_code: '012345',
        enrollment_url: a_string_matching(/enroll\/012345/),
        default_open_time: '00:01',
        default_due_time: '07:00',
        is_archived: false
      })
    end

    it 'ensures the person is a teacher of the course' do
      rescuing_exceptions do
        api_post :create, teacher_token, parameters: { course_id: other_course.id },
                                         raw_post_data: { name: '7th Period' }.to_json
      end

      expect(response).to have_http_status(:forbidden)
    end

    it "allows same name on periods if the previous one was deleted" do
      period = FactoryGirl.create :course_membership_period, course: course, name: '8th Period'
      period.to_model.destroy

      api_post :create, teacher_token, parameters: { course_id: course.id },
                                       raw_post_data: { name: '8th Period' }.to_json

      expect(response).to have_http_status(:created)
      expect(response.body_as_hash[:name]).to eq('8th Period')
    end
  end

  describe '#update' do
    let(:period) { FactoryGirl.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to rename periods' do
      api_patch :update, teacher_token, parameters: { id: period.id },
                                        raw_post_data: { name: 'Skip class!!!' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:name]).to eq('Skip class!!!')
    end

    it 'allows teachers to change the enrollment code' do
      api_patch :update, teacher_token,
        parameters: { id: period.id },
        raw_post_data: { enrollment_code: 'handsome programmer' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:enrollment_code]).to eq('handsome programmer')
    end

    it 'ensures the person is a teacher of the course' do
      other_period = FactoryGirl.create :course_membership_period, course: other_course

      rescuing_exceptions do
        api_put :update, teacher_token, parameters: { id: other_period.id },
                                        raw_post_data: { name: '7th Period' }
      end

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows teachers to change the default open time' do
      api_patch :update, teacher_token,
        parameters: { id: period.id },
        raw_post_data: { default_open_time: '18:32' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:default_open_time]).to eq('18:32')
    end

    it 'freaks if the default open time is in a bad format' do
      expect {
        api_patch :update, teacher_token,
          parameters: { id: period.id },
          raw_post_data: { default_open_time: '1:00' }.to_json
      }.not_to change{ period.to_model.reload.default_open_time }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'allows teachers to change the default due time' do
      api_patch :update, teacher_token,
        parameters: { id: period.id },
        raw_post_data: { default_due_time: '18:33' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:default_due_time]).to eq('18:33')
    end

    it 'freaks if the default due time is in a bad format' do
      expect {
        api_patch :update, teacher_token,
          parameters: { id: period.id },
          raw_post_data: { default_due_time: '25:00' }.to_json
      }.not_to change{ period.to_model.reload.default_open_time }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context '#destroy' do
    let(:period) { FactoryGirl.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to delete periods' do
      api_delete :destroy, teacher_token, parameters: { id: period.id }

      expect(response).to have_http_status(:ok)
      period.to_model.reload
      expect(response.body).to eq Api::V1::PeriodRepresenter.new(period).to_json
      expect(period.to_model.reload).to be_deleted
    end

    it 'ensures the person is a teacher of the course' do
      period.to_model.update_attribute :course, other_course

      expect{
        api_delete :destroy, teacher_token, parameters: { id: period.id }
      }.to raise_error(SecurityTransgression)

      expect(period.to_model.reload).not_to be_deleted
    end

    it 'does not delete periods already deleted' do
      period.to_model.destroy

      api_delete :destroy, teacher_token, parameters: { id: period.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'period_is_already_deleted'
      expect(period.to_model.reload).to be_deleted
    end
  end

  context '#restore' do
    let(:period) { FactoryGirl.create :course_membership_period, course: course }

    before { period.to_model.destroy! }

    it 'allows teachers to restore periods' do
      api_put :restore, teacher_token, parameters: { id: period.id }

      expect(response).to have_http_status(:ok)
      period.to_model.reload
      expect(response.body).to eq Api::V1::PeriodRepresenter.new(period).to_json
      expect(period.to_model.reload).not_to be_deleted
    end

    it 'ensures the person is a teacher of the course' do
      period.to_model.update_attribute :course, other_course

      expect{
        api_put :restore, teacher_token, parameters: { id: period.id }
      }.to raise_error(SecurityTransgression)

      expect(period.to_model.reload).to be_deleted
    end

    it 'does not restore periods that are not deleted' do
      period.to_model.restore!(recursive: true)

      api_put :restore, teacher_token, parameters: { id: period.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'period_is_not_deleted'
      expect(period.to_model.reload).not_to be_deleted
    end

    it 'returns a proper error message if there is a name conflict' do
      conflicting_period = FactoryGirl.create :course_membership_period, course: course,
                                                                         name: period.name

      api_put :restore, teacher_token, parameters: { id: period.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'name_has_already_been_taken'
      expect(period.to_model.reload).to be_deleted
    end
  end
end
