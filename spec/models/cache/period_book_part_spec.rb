require 'rails_helper'

RSpec.describe Cache::PeriodBookPart, type: :model do
  subject(:period_book_part) { FactoryBot.create :cache_period_book_part }

  it { is_expected.to belong_to(:period) }

  it { is_expected.to validate_presence_of(:book_part_uuid) }
  it { is_expected.to validate_presence_of(:clue) }

  it do
    is_expected.to(
      validate_uniqueness_of(:book_part_uuid).scoped_to(:course_membership_period_id)
                                             .case_insensitive
    )
  end
end
