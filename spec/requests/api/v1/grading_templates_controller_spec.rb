require 'rails_helper'

RSpec.describe Api::V1::GradingTemplatesController, type: :request, api: true, version: :v1 do
  let(:course)             { FactoryBot.create :course_profile_course, num_teachers: 1 }
  let(:teacher_profile_id) { course.teachers.first.role.user_profile_id }
  let(:teacher_token)      do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: teacher_profile_id
  end
  let!(:grading_template)  { FactoryBot.create :tasks_grading_template, course: course }

  context '#index' do
    it "returns all of the given course's grading templates" do
      api_get api_course_grading_templates_path(course), teacher_token

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:total_count]).to eq 1
      expect(response.body_as_hash[:items]).to eq [
        Api::V1::GradingTemplateRepresenter.new(grading_template).to_hash.deep_symbolize_keys
      ]
    end
  end
end
