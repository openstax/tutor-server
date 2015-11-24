require 'rails_helper'

RSpec.describe Tasks::Models::ConceptCoachTask, type: :model do
  subject(:concept_coach_task) { FactoryGirl.create(:tasks_concept_coach_task) }

  it { is_expected.to belong_to(:page) }
  it { is_expected.to belong_to(:role) }
  it { is_expected.to belong_to(:task) }

  it { is_expected.to validate_presence_of(:page) }
  it { is_expected.to validate_presence_of(:role) }
  it { is_expected.to validate_presence_of(:task) }

  it { is_expected.to validate_uniqueness_of(:role).scoped_to(:content_page_id) }
  it { is_expected.to validate_uniqueness_of(:task) }
end
