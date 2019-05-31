require 'rails_helper'

RSpec.describe Api::V1::RolesController, type: :controller, api: true, version: :v1 do
  let(:teacher_student)  { FactoryBot.create :course_membership_teacher_student }
  let(:course)           { teacher_student.course }
  let(:role)             { teacher_student.role }
  let(:user)             { role.profile }
  let(:default_role)     { Role::GetDefaultUserRole[user] }
  let(:other_user)       { FactoryBot.create :user }

  let(:user_token)       { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user.id }
  let(:other_user_token) do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: other_user.id
  end

  context '#become' do
    it 'allows users to become one of their roles' do
      api_put :become, user_token, params: { id: role.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq Api::V1::RoleRepresenter.new(role).to_json
      expect(session[:roles][course.id.to_s]).to eq role.id
    end

    it 'ensures the role belongs to the calling user' do
      expect do
        api_put :become, other_user_token, params: { id: role.id }
      end.to raise_error(SecurityTransgression)
         .and not_change { session[:roles] }
    end

    it 'does not let the user become the default role' do
      expect do
        api_put :become, user_token, params: { id: default_role.id }
      end.to not_change { session[:roles] }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to eq(
        {
          errors: [ { code: 'invalid_role', message: 'You cannot become the specified role' } ]
        }.to_json
      )
    end
  end
end
