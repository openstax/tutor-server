require 'rails_helper'

RSpec.describe Ratings::RoleBookPart, type: :model do
  subject(:role_book_part) { FactoryBot.create :ratings_role_book_part }

  it { is_expected.to belong_to(:role) }

  it { is_expected.to validate_presence_of(:book_part_uuid) }
  it { is_expected.to validate_presence_of(:clue) }

  it do
    is_expected.to(
      validate_uniqueness_of(:book_part_uuid).scoped_to(:entity_role_id).case_insensitive
    )
  end
end
