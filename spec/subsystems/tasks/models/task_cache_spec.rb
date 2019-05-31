require 'rails_helper'

RSpec.describe Tasks::Models::TaskCache, type: :model do
  subject(:task_cache) { FactoryBot.create :tasks_task_cache }

  it { is_expected.to belong_to(:task) }
  it { is_expected.to belong_to(:ecosystem) }

  it { is_expected.to validate_presence_of(:task_type) }

  it { is_expected.to validate_uniqueness_of(:ecosystem).scoped_to(:tasks_task_id) }
end
