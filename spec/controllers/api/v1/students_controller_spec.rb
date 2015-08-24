require 'rails_helper'

describe Api::V1::StudentsController, type: :controller, api: true, version: :v1 do

  let!(:application)       { FactoryGirl.create :doorkeeper_application }

  let!(:course)            { Entity::Course.create }
  let!(:period)            { CreatePeriod[course: course] }
  let!(:period_2)          { CreatePeriod[course: course] }

  let!(:student_profile)   { FactoryGirl.create(:user_profile) }
  let!(:student_user)      { student_profile.entity_user }
  let!(:student_role)      {
    role = Entity::Role.create
    Role::Models::RoleUser.create!(user: student_user, role: role)
    role
  }
  let!(:student)           { CourseMembership::AddStudent[role: student_role, period: period] }
  let!(:student_token)     { FactoryGirl.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: student_profile.id }

  let!(:teacher_profile)   { FactoryGirl.create(:user_profile) }
  let!(:teacher_user)      { teacher_profile.entity_user }
  let!(:teacher_role)      {
    role = Entity::Role.create
    Role::Models::RoleUser.create!(user: teacher_user, role: role)
    role
  }
  let!(:teacher)           { CourseMembership::AddTeacher[role: teacher_role, course: course] }
  let!(:teacher_token)     { FactoryGirl.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: teacher_profile.id }

  let!(:student_profile_2) { FactoryGirl.create(:user_profile) }
  let!(:student_user_2)    { student_profile_2.entity_user }
  let!(:student_role_2)    {
    role = Entity::Role.create
    Role::Models::RoleUser.create!(user: student_user_2, role: role)
    role
  }
  let!(:student_2)         { CourseMembership::AddStudent[role: student_role_2, period: period] }

  let!(:student_profile_3) { FactoryGirl.create(:user_profile) }
  let!(:student_user_3)    { student_profile_3.entity_user }
  let!(:student_role_3)    {
    role = Entity::Role.create
    Role::Models::RoleUser.create!(user: student_user_3, role: role)
    role
  }
  let!(:student_3)         { CourseMembership::AddStudent[role: student_role_3, period: period_2] }

  let!(:userless_token)    { FactoryGirl.create :doorkeeper_access_token,
                                                application: application,
                                                resource_owner_id: nil }

  describe '#index' do
    let!(:valid_params) { { course_id: course.id } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        it 'returns the course roster' do
          api_get :index, teacher_token, parameters: valid_params
          expect(response).to have_http_status(:ok)
          students = response.body_as_hash
          expect(Set.new students).to eq Set.new [
            {
              id: student.id.to_s,
              first_name: student.first_name,
              last_name: student.last_name,
              name: student.name,
              period_id: period.id.to_s,
              role_id: student_role.id.to_s,
              deidentifier: student.deidentifier,
              is_active: true
            },
            {
              id: student_2.id.to_s,
              first_name: student_2.first_name,
              last_name: student_2.last_name,
              name: student_2.name,
              period_id: period.id.to_s,
              role_id: student_role_2.id.to_s,
              deidentifier: student_2.deidentifier,
              is_active: true
            },
            {
              id: student_3.id.to_s,
              first_name: student_3.first_name,
              last_name: student_3.last_name,
              name: student_3.name,
              period_id: period_2.id.to_s,
              role_id: student_role_3.id.to_s,
              deidentifier: student_3.deidentifier,
              is_active: true
            }
          ]
        end
      end

      context 'caller is not a course teacher' do
        it 'raises SecurityTransgression' do
          expect{
            api_get :index, student_token, parameters: valid_params
          }.to raise_error(SecurityTransgression)
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_get :index, userless_token, parameters: valid_params
        }.to raise_error(SecurityTransgression)
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_get :index, nil, parameters: valid_params
        }.to raise_error(SecurityTransgression)
      end
    end
  end

  # TEMPORARILY SKIPPED UNTIL WE RESURRECT THE ABILITY FOR A TEACHER TO ADD A STUDENT
  # SEE STUDENTS CONTROLLER COMMENT
  #
  # describe '#create' do
  #   let!(:valid_params) { { course_id: course.id } }
  #   let!(:valid_body)   {
  #     {
  #       period_id: period.id.to_s,
  #       username: 'dummyuser',
  #       password: 'pass',
  #       first_name: 'Dummy',
  #       last_name: 'User',
  #       full_name: 'Dummy User'
  #     }
  #   }

  #   context 'caller has an authorization token' do
  #     context 'caller is a course teacher' do
  #       it 'creates a new student' do
  #         expect {
  #           api_post :create, teacher_token, parameters: valid_params, raw_post_data: valid_body
  #         }.to change{ UserProfile::Models::Profile.count }.by(1)
  #         expect(response).to have_http_status(:created)
  #         new_student = CourseMembership::Models::Student.find(response.body_as_hash[:id])
  #         expect(response.body_as_hash).to eq({
  #           id: new_student.id.to_s,
  #           username: 'dummyuser',
  #           first_name: 'Dummy',
  #           last_name: 'User',
  #           full_name: 'Dummy User',
  #           period_id: period.id.to_s,
  #           role_id: new_student.entity_role_id.to_s,
  #           deidentifier: new_student.deidentifier,
  #           is_active: true
  #         })
  #       end
  #     end

  #     context 'caller is not a course teacher' do
  #       it 'raises SecurityTransgression' do
  #         expect {
  #           api_post :create, student_token, parameters: valid_params, raw_post_data: valid_body
  #         }.to raise_error(SecurityTransgression)
  #       end
  #     end
  #   end

  #   context 'caller has an application/client credentials authorization token' do
  #     it 'raises SecurityTransgression' do
  #       expect {
  #         api_post :create, userless_token, parameters: valid_params, raw_post_data: valid_body
  #       }.to raise_error(SecurityTransgression)
  #     end
  #   end

  #   context 'caller does not have an authorization token' do
  #     it 'raises SecurityTransgression' do
  #       expect {
  #         api_post :create, nil, parameters: valid_params, raw_post_data: valid_body
  #       }.to raise_error(SecurityTransgression)
  #     end
  #   end
  # end

  describe '#update' do
    let!(:valid_params) { { id: student.id } }
    let!(:valid_body)   { { period_id: period_2.id.to_s } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        it 'moves the student to another period' do
          api_patch :update, teacher_token, parameters: valid_params, raw_post_data: valid_body
          expect(response).to have_http_status(:ok)
          new_student = CourseMembership::Models::Student.find(response.body_as_hash[:id])
          expect(response.body_as_hash).to eq({
            id: student.id.to_s,
            first_name: student.first_name,
            last_name: student.last_name,
            name: student.name,
            period_id: period_2.id.to_s,
            role_id: student.entity_role_id.to_s,
            deidentifier: student.deidentifier,
            is_active: true
          })
          expect(student.reload.period).to eq period_2.to_model
        end
      end

      context 'caller is not a course teacher' do
        it 'raises SecurityTransgression' do
          expect{
            api_patch :update, student_token, parameters: valid_params, raw_post_data: valid_body
          }.to raise_error(SecurityTransgression)
          expect(student.reload.period).to eq period.to_model
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_patch :update, userless_token, parameters: valid_params, raw_post_data: valid_body
        }.to raise_error(SecurityTransgression)
        expect(student.reload.period).to eq period.to_model
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_patch :update, nil, parameters: valid_params, raw_post_data: valid_body
        }.to raise_error(SecurityTransgression)
        expect(student.reload.period).to eq period.to_model
      end
    end
  end

  describe '#destroy' do
    let!(:valid_params) { { id: student.id } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        it 'removes the student from the course' do
          api_delete :destroy, teacher_token, parameters: valid_params
          expect(response).to have_http_status(:no_content)

          student.reload
          expect(student.persisted?).to eq true
          expect(student.active?).to eq false
        end
      end

      context 'caller is not a course teacher' do
        it 'raises SecurityTransgression' do
          expect{
            api_delete :destroy, student_token, parameters: valid_params
          }.to raise_error(SecurityTransgression)
          expect(student.reload.destroyed?).to eq false
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_delete :destroy, userless_token, parameters: valid_params
        }.to raise_error(SecurityTransgression)
        expect(student.reload.destroyed?).to eq false
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_delete :destroy, nil, parameters: valid_params
        }.to raise_error(SecurityTransgression)
        expect(student.reload.destroyed?).to eq false
      end
    end
  end

end
