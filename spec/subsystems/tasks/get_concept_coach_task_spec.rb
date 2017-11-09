require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetConceptCoachTask, type: :routine do
  let!(:concept_coach_task) { FactoryBot.create :tasks_concept_coach_task }

  let(:role)                { concept_coach_task.role }
  let(:another_role)        { FactoryBot.create :entity_role }

  let(:page)                { Content::Page.new(strategy: concept_coach_task.page.wrap) }
  let(:another_page)        do
    page_model = FactoryBot.create :content_page
    Content::Page.new(strategy: page_model.wrap)
  end

  context 'with an existing ConceptCoachTask' do
    it 'retrieves the existing task' do
      task = nil
      expect{ task = described_class[role: role, page: page] }.not_to(
        change{ Tasks::Models::ConceptCoachTask.count }
      )
      expect(task.taskings.any?{ |ts| ts.role == role }).to eq true
    end
  end

  context 'with no matching ConceptCoachTask' do
    it 'returns nil' do
      task = nil
      expect{ task = described_class[role: another_role, page: page] }.not_to(
        change{ Tasks::Models::ConceptCoachTask.count }
      )
      expect(task).to be_nil

      expect{ task = described_class[role: role, page: another_page] }.not_to(
        change{ Tasks::Models::ConceptCoachTask.count }
      )
      expect(task).to be_nil
    end
  end
end
