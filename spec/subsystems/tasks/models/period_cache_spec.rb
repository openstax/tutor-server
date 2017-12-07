require 'rails_helper'

RSpec.describe Tasks::Models::PeriodCache, type: :model do
  subject(:period_cache) { FactoryBot.create :tasks_period_cache }

  it { is_expected.to belong_to(:period)    }
  it { is_expected.to belong_to(:ecosystem) }
  it { is_expected.to belong_to(:task_plan) }

  it { is_expected.to validate_presence_of(:period)    }
  it { is_expected.to validate_presence_of(:ecosystem) }

  it do
    is_expected.to(
      validate_uniqueness_of(:task_plan)
        .scoped_to(:content_ecosystem_id, :course_membership_period_id)
    )
  end
end
