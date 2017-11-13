require 'rails_helper'

RSpec.describe Tasks::Models::ConceptCoachTask, type: :model do
  subject(:concept_coach_task) { FactoryBot.create(:tasks_concept_coach_task) }

  it { is_expected.to belong_to(:page) }
  it { is_expected.to belong_to(:role) }
  it { is_expected.to belong_to(:task) }

  it { is_expected.to validate_presence_of(:page) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_presence_of(:task) }

  it { is_expected.to validate_uniqueness_of(:role).scoped_to(:content_page_id) }
  it { is_expected.to validate_uniqueness_of(:task) }

  it 'requires the role to match the role the task is assigned to' do
    concept_coach_task.task.taskings.first.role = FactoryBot.create :entity_role
    expect(concept_coach_task).not_to be_valid
    expect(concept_coach_task.errors.first).to(
      eq [:role, 'must match the role the task is assigned to']
    )
  end
end
