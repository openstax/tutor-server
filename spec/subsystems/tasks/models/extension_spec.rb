require 'rails_helper'

RSpec.describe Tasks::Models::Extension, type: :model do
  subject(:extension) { FactoryBot.create :tasks_extension }

  it { is_expected.to belong_to(:task_plan) }
  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_uniqueness_of(:role).scoped_to(:tasks_task_plan_id) }

  it { is_expected.to validate_presence_of(:due_at_ntz) }
  it { is_expected.to validate_presence_of(:closes_at_ntz) }

  it 'requires closes_at to be after due_at' do
    expect(extension).to be_valid

    extension.closes_at = Time.current - 2.days - 1.hour
    expect(extension).to_not be_valid
  end
end
