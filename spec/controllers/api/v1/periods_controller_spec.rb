require 'rails_helper'

RSpec.describe Api::V1::PeriodsController, type: :controller, api: true, version: :v1 do
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:other_course)  { FactoryBot.create :course_profile_course }

  let(:teacher_user)  { FactoryBot.create(:user) }

  let(:teacher_token) { FactoryBot.create(:doorkeeper_access_token,
                                           resource_owner_id: teacher_user.id) }

  before { AddUserAsCourseTeacher[course: course, user: teacher_user] }

  context '#create' do
    it 'allows teachers to create periods' do
      allow(SecureRandom).to receive(:random_number) { 12345 }

      api_post :create, teacher_token, params: { course_id: course.id },
                                       body: { name: '7th Period' }.to_json

      expect(response).to have_http_status(:created)

      last_period = CourseMembership::Models::Period.last
      expect(response.body_as_hash).to match(a_hash_including(
        id: last_period.id.to_s,
        name: '7th Period',
        num_enrolled_students: 0,
        enrollment_code: '012345',
        enrollment_url: a_string_matching(/enroll\/012345/),
        is_archived: false
      ))
    end

    it 'ensures the person is a teacher of the course' do
      rescuing_exceptions do
        api_post :create, teacher_token, params: { course_id: other_course.id },
                                         body: { name: '7th Period' }.to_json
      end

      expect(response).to have_http_status(:forbidden)
    end

    it "allows same name on periods if the previous one was deleted" do
      period = FactoryBot.create :course_membership_period, course: course, name: '8th Period'
      period.to_model.destroy

      api_post :create, teacher_token, params: { course_id: course.id },
                                       body: { name: '8th Period' }.to_json

      expect(response).to have_http_status(:created)
      expect(response.body_as_hash[:name]).to eq('8th Period')
    end
  end

  context '#update' do
    let(:period) { FactoryBot.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to rename periods' do
      api_patch :update, teacher_token, params: { id: period.id },
                                        body: { name: 'Skip class!!!' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:name]).to eq('Skip class!!!')
    end

    it 'allows teachers to change the enrollment code' do
      api_patch :update, teacher_token,
        params: { id: period.id },
        body: { enrollment_code: 'handsome programmer' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:enrollment_code]).to eq('handsome programmer')
    end

    it 'ensures the person is a teacher of the course' do
      other_period = FactoryBot.create :course_membership_period, course: other_course

      rescuing_exceptions do
        api_put :update, teacher_token, params: { id: other_period.id },
                                        body: { name: '7th Period' }
      end

      expect(response).to have_http_status(:forbidden)
    end
  end

  context '#destroy' do
    let(:period) { FactoryBot.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to delete periods' do
      api_delete :destroy, teacher_token, params: { id: period.id }

      expect(response).to have_http_status(:ok)
      period.to_model.reload
      expect(response.body).to eq Api::V1::PeriodRepresenter.new(period).to_json
      expect(period.to_model.reload).to be_deleted
    end

    it 'ensures the person is a teacher of the course' do
      period.to_model.update_attribute :course, other_course

      expect do
        api_delete :destroy, teacher_token, params: { id: period.id }
      end.to raise_error(SecurityTransgression)

      expect(period.to_model.reload).not_to be_deleted
    end

    it 'does not delete periods already deleted' do
      period.to_model.destroy

      api_delete :destroy, teacher_token, params: { id: period.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'period_is_already_deleted'
      expect(period.to_model.reload).to be_deleted
    end
  end

  context '#restore' do
    let(:period) { FactoryBot.create :course_membership_period, course: course }

    before { period.to_model.destroy! }

    it 'allows teachers to restore periods' do
      api_put :restore, teacher_token, params: { id: period.id }

      expect(response).to have_http_status(:ok)
      period.to_model.reload
      expect(response.body).to eq Api::V1::PeriodRepresenter.new(period).to_json
      expect(period.to_model.reload).not_to be_deleted
    end

    it 'ensures the person is a teacher of the course' do
      period.to_model.update_attribute :course, other_course

      expect do
        api_put :restore, teacher_token, params: { id: period.id }
      end.to raise_error(SecurityTransgression)

      expect(period.to_model.reload).to be_deleted
    end

    it 'does not restore periods that are not deleted' do
      period.to_model.restore!

      api_put :restore, teacher_token, params: { id: period.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'period_is_not_deleted'
      expect(period.to_model.reload).not_to be_deleted
    end

    it 'returns a proper error message if there is a name conflict' do
      FactoryBot.create :course_membership_period, course: course, name: period.name

      api_put :restore, teacher_token, params: { id: period.id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'name_has_already_been_taken'
      expect(period.to_model.reload).to be_deleted
    end
  end

  context '#teacher_student' do
    let(:period) { FactoryBot.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to create or reset teacher_students' do
      period_wrapper = CourseMembership::Period.new strategy: period.wrap
      expect(CreateOrResetTeacherStudent).to(
        receive(:call).with(period: period_wrapper, user: teacher_user)
      ).and_call_original
      api_put :teacher_student, teacher_token, params: { id: period.id }

      expect(response).to have_http_status(:ok)

      role = CourseMembership::Models::TeacherStudent.order(:created_at).last.role
      expect(response.body).to eq Api::V1::RoleRepresenter.new(role).to_json
    end

    it 'ensures the person is a teacher of the course' do
      period.to_model.update_attribute :course, other_course

      expect(CreateOrResetTeacherStudent).not_to receive(:call)

      expect do
        api_put :teacher_student, teacher_token, params: { id: period.id }
      end.to raise_error(SecurityTransgression)
    end
  end
end
