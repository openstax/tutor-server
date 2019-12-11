require 'rails_helper'

RSpec.describe Api::V1::GradingTemplatesController, type: :request, api: true, version: :v1 do
  let(:course)             { FactoryBot.create :course_profile_course, num_teachers: 1 }
  let(:teacher_profile_id) { course.teachers.first.role.user_profile_id }
  let(:teacher_token)      do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: teacher_profile_id
  end
  let!(:grading_template)  { FactoryBot.create :tasks_grading_template, course: course }

  context 'GET /api/courses/1/grading_templates' do
    it "returns all of the given course's grading templates" do
      api_get api_course_grading_templates_path(course), teacher_token

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash[:total_count]).to eq 1
      expect(response.body_as_hash[:items]).to eq [
        Api::V1::GradingTemplateRepresenter.new(grading_template).to_hash.deep_symbolize_keys
      ]
    end
  end

  context 'POST /api/courses/1/grading_templates' do
    it 'creates a new grading template for the course' do
      expect do
        api_post api_course_grading_templates_path(course), teacher_token,
                 params: Api::V1::GradingTemplateRepresenter.new(
                   grading_template
                 ).to_hash.except('id', 'course_id').to_json
      end.to change { Tasks::Models::GradingTemplate.count }.by(1)

      expect(response).to have_http_status(:created)
      expect(response.body_as_hash.except(:id, :created_at)).to eq(
        Api::V1::GradingTemplateRepresenter.new(
          grading_template
        ).to_hash.deep_symbolize_keys.except(:id, :created_at)
      )
    end
  end

  context 'PATCH /api/grading_templates/1' do
    let(:grading_template_2) { FactoryBot.create :tasks_grading_template }

    it 'updates the grading template with the given id' do
      expect do
        api_patch api_grading_template_path(grading_template), teacher_token,
                  params: Api::V1::GradingTemplateRepresenter.new(
                    grading_template_2
                  ).to_hash.except('id', 'course_id').to_json
      end.to change { grading_template.reload.updated_at }

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash.slice(:id, :course_id, :created_at)).to eq(
        Api::V1::GradingTemplateRepresenter.new(
          grading_template
        ).to_hash.deep_symbolize_keys.slice(:id, :course_id, :created_at)
      )
      expect(response.body_as_hash.except(:id, :course_id, :created_at)).to eq(
        Api::V1::GradingTemplateRepresenter.new(
          grading_template_2
        ).to_hash.deep_symbolize_keys.except(:id, :course_id, :created_at)
      )
    end
  end

  context 'DELETE /api/grading_templates/1' do
    it 'deletes the grading template with the given id' do
      FactoryBot.create(
        :tasks_grading_template, course: course, task_plan_type: grading_template.task_plan_type
      )
      expect do
        api_delete api_grading_template_path(grading_template), teacher_token
      end.not_to change { Tasks::Models::GradingTemplate.count }
      expect(grading_template.reload.deleted?).to eq true

      expect(response).to have_http_status(:ok)
      expect(response.body_as_hash).to eq Api::V1::GradingTemplateRepresenter.new(
        grading_template
      ).to_hash.deep_symbolize_keys
    end
  end
end
