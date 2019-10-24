require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::Research::RootController, type: :controller, api: true, version: :v1 do
  let(:course_1)      { FactoryBot.create :course_profile_course }
  let(:period)        { FactoryBot.create :course_membership_period, course: course_1 }
  let(:student_user)  { FactoryBot.create :user }
  let(:student_role)  { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student_1)    { student_role.student }
  let!(:student_2)    { FactoryBot.create :course_membership_student, period: period }

  let!(:course_2)     { FactoryBot.create :course_profile_course }

  let(:research_user) { FactoryBot.create :user, :researcher }
  let(:research_token) do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: research_user.id
  end

  context 'GET #research' do
    context 'course_ids' do
      let(:params) { { course_ids: [ course_1.id ] } }

      it 'retrieves period, student and task info for courses with the given ids' do
        api_post :research, research_token, body: params.to_json

        expect(response).to be_ok
        expect(response.body).to eq Api::V1::Research::CoursesRepresenter.new([ course_1 ]).to_json
      end
    end

    context 'research_identifiers' do
      let(:research_identifiers) { [ student_role.research_identifier ] }
      let(:params)               { { research_identifiers: research_identifiers } }

      it 'retrieves course, period and task info for students with the given research_identifier' do
        api_post :research, research_token, body: params.to_json

        expect(response).to be_ok
        # Only students that match the given research_identifiers will be returned
        expect(response.body).to eq Api::V1::Research::CoursesRepresenter.new([ course_1 ]).to_json(
          user_options: { research_identifiers: research_identifiers }
        )
      end
    end
  end
end
