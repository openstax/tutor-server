require 'rails_helper'

RSpec.describe Api::V1::PeriodsController, type: :request, api: true, version: :v1 do
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:other_course)  { FactoryBot.create :course_profile_course }

  let(:teacher_user)  { FactoryBot.create(:user_profile) }

  let(:teacher_token) { FactoryBot.create(:doorkeeper_access_token,
                                           resource_owner_id: teacher_user.id) }

  before { AddUserAsCourseTeacher[course: course, user: teacher_user] }

  context '#create' do
    it 'allows teachers to create periods' do
      allow(SecureRandom).to receive(:random_number) { 12345 }

      api_post api_course_periods_url(course.id), teacher_token,
               params: { name: '7th Period' }.to_json

      expect(response).to have_http_status(:created)

      last_period = CourseMembership::Models::Period.last
      expect(response.body_as_hash).to match(a_hash_including(
        id: last_period.id.to_s,
        name: '7th Period',
        num_enrolled_students: 0,
        enrollment_code: '012345',
        enrollment_url: a_string_matching(/enroll\/012345/),
        default_open_time: '00:01',
        default_due_time: '07:00',
        is_archived: false
      ))
    end

    it 'ensures the person is a teacher of the course' do
      rescuing_exceptions do
        api_post api_course_periods_url(other_course.id), teacher_token,
                 params: { name: '7th Period' }.to_json
      end

      expect(response).to have_http_status(:forbidden)
    end

    it "allows same name on periods if the previous one was deleted" do
      period = FactoryBot.create :course_membership_period, course: course, name: '8th Period'
      period.destroy

      api_post api_course_periods_url(course.id), teacher_token,
               params: { name: '8th Period' }.to_json

      expect(response).to have_http_status(:created)
      expect(response.body_as_hash[:name]).to eq('8th Period')
    end
  end

  context '#update' do
    let(:period) { FactoryBot.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to rename periods' do
      api_patch api_period_url(period.id), teacher_token, params: { name: 'Skip class!!!' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:name]).to eq('Skip class!!!')
    end

    it 'allows teachers to change the enrollment code' do
      api_patch api_period_url(period.id), teacher_token,
                params: { enrollment_code: 'handsome programmer' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:enrollment_code]).to eq('handsome programmer')
    end

    it 'ensures the person is a teacher of the course' do
      other_period = FactoryBot.create :course_membership_period, course: other_course

      rescuing_exceptions do
        api_put api_period_url(other_period.id), teacher_token,
                params: { name: '7th Period' }.to_json
      end

      expect(response).to have_http_status(:forbidden)
    end

    it 'allows teachers to change the default open time' do
      api_patch api_period_url(period.id), teacher_token,
                params: { default_open_time: '18:32' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:default_open_time]).to eq('18:32')
    end

    it 'freaks if the default open time is in a bad format' do
      expect {
        api_patch api_period_url(period.id), teacher_token,
                  params: { default_open_time: '1:00' }.to_json
      }.not_to change { period.reload.default_open_time }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'allows teachers to change the default due time' do
      api_patch api_period_url(period.id), teacher_token,
                params: { default_due_time: '18:33' }.to_json

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:default_due_time]).to eq('18:33')
    end

    it 'freaks if the default due time is in a bad format' do
      expect {
        api_patch api_period_url(period.id), teacher_token,
                  params: { default_due_time: '25:00' }.to_json
      }.not_to change { period.reload.default_open_time }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context '#destroy' do
    let(:period) { FactoryBot.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to delete periods' do
      api_delete api_period_url(period.id), teacher_token

      expect(response).to have_http_status(:ok)
      period.reload
      expect(response.body).to eq Api::V1::PeriodRepresenter.new(period).to_json
      expect(period.reload).to be_deleted
    end

    it 'ensures the person is a teacher of the course' do
      period.update_attribute :course, other_course

      expect do
        api_delete api_period_url(period.id), teacher_token
      end.to raise_error(SecurityTransgression)

      expect(period.reload).not_to be_deleted
    end

    it 'does not delete periods already deleted' do
      period.destroy

      api_delete api_period_url(period.id), teacher_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'period_is_already_deleted'
      expect(period.reload).to be_deleted
    end
  end

  context '#restore' do
    let(:period) { FactoryBot.create :course_membership_period, course: course }

    before { period.destroy! }

    it 'allows teachers to restore periods' do
      api_put restore_api_period_url(period.id), teacher_token

      expect(response).to have_http_status(:ok)
      period.reload
      expect(response.body).to eq Api::V1::PeriodRepresenter.new(period).to_json
      expect(period.reload).not_to be_deleted
    end

    it 'ensures the person is a teacher of the course' do
      period.update_attribute :course, other_course

      expect do
        api_put restore_api_period_url(period.id), teacher_token
      end.to raise_error(SecurityTransgression)

      expect(period.reload).to be_deleted
    end

    it 'does not restore periods that are not deleted' do
      period.restore!

      api_put restore_api_period_url(period.id), teacher_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'period_is_not_deleted'
      expect(period.reload).not_to be_deleted
    end

    it 'returns a proper error message if there is a name conflict' do
      FactoryBot.create :course_membership_period, course: course, name: period.name

      api_put restore_api_period_url(period.id), teacher_token

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'name_has_already_been_taken'
      expect(period.reload).to be_deleted
    end
  end

  context '#teacher_student' do
    let(:period) { FactoryBot.create :course_membership_period, course: course, name: '8th Period' }

    it 'allows teachers to create or reset teacher_students' do
      expect(CreateOrResetTeacherStudent).to(
        receive(:call).with(period: period, user: teacher_user)
      ).and_call_original
      api_put teacher_student_api_period_url(period.id), teacher_token

      expect(response).to have_http_status(:ok)

      role = CourseMembership::Models::TeacherStudent.order(:created_at).last.role
      expect(response.body).to eq Api::V1::RoleRepresenter.new(role).to_json
    end

    it 'ensures the person is a teacher of the course' do
      period.update_attribute :course, other_course

      expect(CreateOrResetTeacherStudent).not_to receive(:call)

      expect do
        api_put teacher_student_api_period_url(period.id), teacher_token
      end.to raise_error(SecurityTransgression)
    end
  end
end
