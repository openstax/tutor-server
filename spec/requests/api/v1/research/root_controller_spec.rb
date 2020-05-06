require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::Research::RootController, type: :request, api: true, version: :v1 do
  let(:task_plan)        { FactoryBot.create :tasked_task_plan, number_of_students: 2 }
  let(:course_1)         { task_plan.course }
  let(:period)           { task_plan.tasking_plans.first.target }
  let(:student_1)        { period.students.to_a.first }
  let(:student_2)        { period.students.to_a.last }
  let!(:teacher_student) { FactoryBot.create :course_membership_teacher_student, period: period }

  let!(:course_2)        { FactoryBot.create :course_profile_course }

  let(:research_user)    { FactoryBot.create :user_profile, :researcher }
  let(:research_token)   do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: research_user.id
  end

  before                 { DistributeTasks.call task_plan: task_plan }

  context 'POST #research' do
    context 'course_ids' do
      let(:params) { { course_ids: [ course_1.id ] } }

      it 'retrieves period, student and task info for courses with the given ids' do
        api_post api_research_url, research_token, params: params.to_json

        expect(response).to be_ok
        expect(response.body).to eq Api::V1::Research::CoursesRepresenter.new([ course_1 ]).to_json
      end
    end

    context 'research_identifiers' do
      let(:research_identifiers) { [ student_1.research_identifier ] }
      let(:params)               { { research_identifiers: research_identifiers } }

      it 'retrieves course, period and tasks for students with the given research_identifiers' do
        api_post api_research_url, research_token, params: params.to_json

        expect(response).to be_ok
        # Only students that match the given research_identifiers will be returned
        expect(response.body).to eq Api::V1::Research::CoursesRepresenter.new([ course_1 ]).to_json(
          user_options: { research_identifiers: research_identifiers }
        )
      end
    end
  end
end
